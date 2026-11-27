import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/data/services/platform/system_monitor/system_monitor_service.dart';
import 'package:path/path.dart' as p;

/// Linux: `/proc` and `/sys` files, plus `df` / `lsblk` / `lspci` for the
/// drive and GPU. No native code. See docs/features/system.md.
@LazySingleton(as: SystemMonitorService, env: [PlatformEnv.linux])
final class LinuxSystemMonitorService({required final AppDirectories _directories}) implements SystemMonitorService {
  static const _powerSupplies = '/sys/class/power_supply';

  @override
  Future<SystemCapabilitiesMsg> capabilities() async => SystemCapabilitiesMsg(
    memory: File('/proc/meminfo').existsSync(),
    cpu: File('/proc/stat').existsSync(),
    gpu: _gpuBusyFiles().isNotEmpty,
    network: File('/proc/net/dev').existsSync(),
    storage: true,
    battery: _battery() != null,
  );

  @override
  Future<SystemSampleMsg> sample() async {
    final memory = _memory();
    final cpu = _cpuTicks();
    final network = _network();
    final gpu = [for (final file in _gpuBusyFiles()) ?double.tryParse(_read(file.path) ?? '')];
    return SystemSampleMsg(
      uptimeMillis: _uptimeMillis(),
      memoryUsedBytes: memory?.used,
      memoryTotalBytes: memory?.total,
      cpuBusyTicks: cpu?.busy,
      cpuTotalTicks: cpu?.total,
      gpuPercent: gpu.isEmpty ? null : gpu.reduce((a, b) => a > b ? a : b),
      networkRxBytes: network?.rx,
      networkTxBytes: network?.tx,
    );
  }

  @override
  Future<SystemStorageMsg> storage() async {
    // GNU df: byte counts for the file system holding the app's folder.
    final result = await Process.run('df', ['-B1', '--output=size,avail', _directories.base]);
    final lines = const LineSplitter().convert(result.stdout as String);
    if (result.exitCode != 0 || lines.length < 2) {
      return SystemStorageMsg();
    }
    final values = lines[1].trim().split(RegExp(r'\s+')).map(int.tryParse).toList();
    return SystemStorageMsg(totalBytes: values.firstOrNull, freeBytes: values.elementAtOrNull(1));
  }

  @override
  Future<SystemBatteryMsg> battery() async {
    final dir = _battery();
    if (dir == null) {
      return SystemBatteryMsg(state: .unknown);
    }
    int? value(String name) => int.tryParse(_read(p.join(dir, name)) ?? '');
    // charge_* in µAh; some batteries report energy_* in µWh instead, which
    // the design voltage (µV) turns into mAh.
    final voltage = value('voltage_min_design');
    int? mah(String charge, String energy) => switch ((value(charge), value(energy), voltage)) {
      (final micro?, _, _) when micro > 0 => micro ~/ 1000,
      (_, final microWh?, final microV?) when microWh > 0 && microV > 0 => microWh * 1000 ~/ microV,
      _ => null,
    };
    final design = mah('charge_full_design', 'energy_full_design');
    final full = mah('charge_full', 'energy_full');
    final cycles = value('cycle_count');
    return SystemBatteryMsg(
      levelPercent: value('capacity')?.toDouble(),
      state: switch (_read(p.join(dir, 'status'))) {
        'Charging' => .charging,
        'Discharging' => .discharging,
        'Full' => .full,
        'Not charging' => .notCharging,
        _ => .unknown,
      },
      healthPercent: design != null && full != null && design > 0 ? (full * 100 / design).clamp(0, 100) : null,
      cycleCount: cycles != null && cycles > 0 ? cycles : null,
      designCapacityMah: design,
      fullChargeCapacityMah: full,
      remainingCapacityMah: mah('charge_now', 'energy_now'),
    );
  }

  @override
  Future<SystemHardwareMsg> hardware() async {
    final cpuInfo = _read('/proc/cpuinfo') ?? '';
    final (gpuName, drive) = await (_gpuName(), _drive()).wait;
    final maxFrequencies = [
      for (var cpu = 0; cpu < Platform.numberOfProcessors; cpu++)
        ?int.tryParse(_read('/sys/devices/system/cpu/cpu$cpu/cpufreq/cpuinfo_max_freq') ?? ''),
    ];
    return SystemHardwareMsg(
      cpuName: _cpuInfoValue(cpuInfo, 'model name') ?? _cpuInfoValue(cpuInfo, 'Hardware'),
      cpuCores: _physicalCores(cpuInfo),
      cpuThreads: Platform.numberOfProcessors,
      // kHz → MHz.
      cpuMaxFrequencyMhz: maxFrequencies.isEmpty ? null : maxFrequencies.reduce((a, b) => a > b ? a : b) ~/ 1000,
      gpuName: gpuName,
      storageModel: drive?.model,
      storageSolidState: drive?.solidState,
      storageNvme: drive?.nvme,
      storageInterface: drive?.transport,
    );
  }

  int _uptimeMillis() {
    final seconds = double.tryParse(_read('/proc/uptime')?.split(' ').first ?? '');
    return seconds == null ? DateTime.now().millisecondsSinceEpoch : (seconds * 1000).round();
  }

  ({int used, int total})? _memory() {
    final info = {
      for (final line in const LineSplitter().convert(_read('/proc/meminfo') ?? ''))
        if (line.split(':') case [final key, final value]) key: int.tryParse(value.trim().split(' ').first),
    };
    return switch ((info['MemTotal'], info['MemAvailable'])) {
      (final total?, final available?) => (used: (total - available) * 1024, total: total * 1024),
      _ => null,
    };
  }

  /// The first `/proc/stat` line: user nice system idle iowait irq softirq steal.
  ({int busy, int total})? _cpuTicks() {
    final line = _read('/proc/stat')?.split('\n').first;
    if (line == null || !line.startsWith('cpu ')) {
      return null;
    }
    final ticks = line.split(RegExp(r'\s+')).skip(1).map(int.tryParse).nonNulls.toList();
    if (ticks.length < 4) {
      return null;
    }
    final idle = ticks[3] + (ticks.length > 4 ? ticks[4] : 0);
    final total = ticks.take(8).fold(0, (sum, tick) => sum + tick);
    return (busy: total - idle, total: total);
  }

  /// Physical interfaces only (they have a `device` link), so loopback,
  /// bridges, VPN tunnels and container veths don't count twice.
  ({int rx, int tx})? _network() {
    final text = _read('/proc/net/dev');
    if (text == null) {
      return null;
    }
    var rx = 0;
    var tx = 0;
    for (final line in const LineSplitter().convert(text).skip(2)) {
      final parts = line.split(':');
      if (parts.length != 2 || !Directory('/sys/class/net/${parts[0].trim()}/device').existsSync()) {
        continue;
      }
      final fields = parts[1].trim().split(RegExp(r'\s+'));
      if (fields.length >= 9) {
        rx += int.tryParse(fields[0]) ?? 0;
        tx += int.tryParse(fields[8]) ?? 0;
      }
    }
    return (rx: rx, tx: tx);
  }

  /// AMD (and some Intel) drivers report GPU load here.
  List<File> _gpuBusyFiles() {
    final drm = Directory('/sys/class/drm');
    if (!drm.existsSync()) {
      return const [];
    }
    return [
      for (final card in drm.listSync())
        if (RegExp(r'^card\d+$').hasMatch(p.basename(card.path)))
          if (File(p.join(card.path, 'device', 'gpu_busy_percent')) case final file when file.existsSync()) file,
    ];
  }

  /// The system battery (not a mouse or headset: those have scope "Device").
  String? _battery() {
    final dir = Directory(_powerSupplies);
    if (!dir.existsSync()) {
      return null;
    }
    for (final supply in dir.listSync()) {
      if (_read(p.join(supply.path, 'type')) == 'Battery' &&
          _read(p.join(supply.path, 'scope')) != 'Device' &&
          _read(p.join(supply.path, 'capacity')) != null) {
        return supply.path;
      }
    }
    return null;
  }

  String? _cpuInfoValue(String cpuInfo, String key) {
    for (final line in const LineSplitter().convert(cpuInfo)) {
      if (line.split(':') case [final name, final value, ...] when name.trim() == key && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Distinct (physical id, core id) pairs; x86 only, ARM leaves them out.
  int? _physicalCores(String cpuInfo) {
    final cores = <String>{};
    String? physical;
    for (final line in const LineSplitter().convert(cpuInfo)) {
      final parts = line.split(':');
      if (parts.length < 2) {
        continue;
      }
      switch (parts[0].trim()) {
        case 'physical id':
          physical = parts[1].trim();
        case 'core id':
          cores.add('$physical:${parts[1].trim()}');
      }
    }
    return cores.isEmpty ? null : cores.length;
  }

  /// `lspci -mm` rows like `00:02.0 "VGA compatible controller" "Intel Corporation" "Device 4680" ...`.
  Future<String?> _gpuName() async {
    final lines = await _lines('lspci', ['-mm']);
    for (final line in lines) {
      final quoted = RegExp('"([^"]*)"').allMatches(line).map((match) => match.group(1)!).toList();
      if (quoted.length >= 3 &&
          (quoted[0].contains('VGA') || quoted[0].contains('3D') || quoted[0].contains('Display'))) {
        return '${quoted[1]} ${quoted[2]}';
      }
    }
    return null;
  }

  /// The disk holding the app's folder, from `df` (its partition) and `lsblk`.
  Future<({String? model, bool? solidState, bool? nvme, String? transport})?> _drive() async {
    final source = (await _lines('df', ['--output=source', _directories.base])).elementAtOrNull(1)?.trim();
    if (source == null || !source.startsWith('/dev/')) {
      return null;
    }
    final parent = (await _lines('lsblk', ['-no', 'PKNAME', source])).firstOrNull?.trim();
    final disk = parent == null || parent.isEmpty ? p.basename(source) : parent;
    final sys = '/sys/block/$disk';
    if (!Directory(sys).existsSync()) {
      return null;
    }
    final transport = (await _lines('lsblk', ['-dno', 'TRAN', '/dev/$disk'])).firstOrNull?.trim();
    final rotational = _read('$sys/queue/rotational');
    return (
      model: _read('$sys/device/model'),
      solidState: rotational == null ? null : rotational == '0',
      nvme: disk.startsWith('nvme'),
      transport: switch (transport) {
        'nvme' => 'NVMe',
        'sata' => 'SATA',
        'usb' => 'USB',
        null || '' => null,
        final other => other.toUpperCase(),
      },
    );
  }

  Future<List<String>> _lines(String executable, List<String> args) async {
    try {
      final result = await Process.run(executable, args);
      return result.exitCode == 0 ? const LineSplitter().convert(result.stdout as String) : const [];
    } on ProcessException {
      return const [];
    }
  }

  String? _read(String path) {
    try {
      final text = File(path).readAsStringSync().trim();
      return text.isEmpty ? null : text;
    } on FileSystemException {
      return null;
    }
  }
}

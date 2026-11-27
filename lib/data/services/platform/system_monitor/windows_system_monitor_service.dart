import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/platform/system_monitor/system_monitor_service.dart';
import 'package:path/path.dart' as p;

/// Windows: Win32 calls through `dart:ffi` for the live readings, and one
/// PowerShell CIM query for the hardware facts. No native code.
/// See docs/features/system.md.
@LazySingleton(as: SystemMonitorService, env: [PlatformEnv.windows])
final class WindowsSystemMonitorService({required final AppDirectories _directories}) implements SystemMonitorService {
  static const _noBattery = 128;
  static const _unknown = 255;
  static const _charging = 8;

  final _win = _Win32();

  @override
  Future<SystemCapabilitiesMsg> capabilities() async => SystemCapabilitiesMsg(
    memory: true,
    cpu: true,
    gpu: false,
    network: _win.networkBytes() != null,
    storage: true,
    battery: _hasBattery(_win.powerStatus()),
  );

  @override
  Future<SystemSampleMsg> sample() async {
    final memory = _win.memory();
    final cpu = _win.cpuTicks();
    final network = _win.networkBytes();
    return SystemSampleMsg(
      uptimeMillis: _win.uptimeMillis(),
      memoryUsedBytes: memory?.used,
      memoryTotalBytes: memory?.total,
      cpuBusyTicks: cpu?.busy,
      cpuTotalTicks: cpu?.total,
      networkRxBytes: network?.rx,
      networkTxBytes: network?.tx,
    );
  }

  @override
  Future<SystemStorageMsg> storage() async {
    final space = _win.diskSpace(_directories.base);
    return SystemStorageMsg(totalBytes: space?.total, freeBytes: space?.free);
  }

  @override
  Future<SystemBatteryMsg> battery() async {
    final status = _win.powerStatus();
    if (status == null || !_hasBattery(status)) {
      return SystemBatteryMsg(state: .unknown);
    }
    final onPower = status.acLine == 1;
    final state = switch (status) {
      _ when status.flag & _charging != 0 => BatteryStateMsg.charging,
      _ when onPower && status.percent >= 100 => BatteryStateMsg.full,
      _ when onPower => BatteryStateMsg.notCharging,
      _ when status.acLine == 0 => BatteryStateMsg.discharging,
      _ => BatteryStateMsg.unknown,
    };
    // Seconds left; 0xFFFFFFFF when Windows has no estimate yet.
    final seconds = status.secondsLeft;
    return SystemBatteryMsg(
      levelPercent: status.percent.toDouble(),
      state: state,
      minutesRemaining: state == .discharging && seconds != 0xFFFFFFFF && seconds > 0 ? seconds ~/ 60 : null,
    );
  }

  @override
  Future<SystemHardwareMsg> hardware() async {
    final drive = p.rootPrefix(_directories.base).replaceAll(RegExp(r'[:\\/]'), '');
    final script =
        r'''
$ErrorActionPreference = 'SilentlyContinue'
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike '*Basic*' -and $_.Name -notlike '*Remote*' } | Select-Object -First 1 Name
$ram = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1 SMBIOSMemoryType, Manufacturer, ConfiguredClockSpeed, Speed
$part = Get-Partition -DriveLetter '''
        '$drive'
        r'''
$disk = if ($part) { Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$part.DiskNumber } | Select-Object -First 1 FriendlyName, MediaType, BusType } else { $null }
@{ cpu = $cpu; gpu = $gpu; ram = $ram; disk = $disk } | ConvertTo-Json -Compress -Depth 3
''';
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ], stdoutEncoding: utf8);
    final json = jsonDecode((result.stdout as String).trim()) as JsonMap;
    final cpu = json['cpu'] as JsonMap?;
    final gpu = json['gpu'] as JsonMap?;
    final ram = json['ram'] as JsonMap?;
    final disk = json['disk'] as JsonMap?;
    String? text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;
    int? number(Object? value) => value is num && value > 0 ? value.toInt() : null;
    // Get-PhysicalDisk enums arrive as numbers: MediaType 3 HDD, 4 SSD;
    // BusType 7 USB, 11 SATA, 17 NVMe (others named by their own label).
    final mediaType = disk?['MediaType'];
    final busType = disk?['BusType'];
    return SystemHardwareMsg(
      cpuName: text(cpu?['Name']),
      cpuCores: number(cpu?['NumberOfCores']),
      cpuThreads: number(cpu?['NumberOfLogicalProcessors']) ?? Platform.numberOfProcessors,
      cpuMaxFrequencyMhz: number(cpu?['MaxClockSpeed']),
      gpuName: text(gpu?['Name']),
      memoryType: _memoryType(ram?['SMBIOSMemoryType']),
      memoryManufacturer: text(ram?['Manufacturer']),
      memorySpeedMhz: number(ram?['ConfiguredClockSpeed']) ?? number(ram?['Speed']),
      storageModel: text(disk?['FriendlyName']),
      storageSolidState: switch (mediaType) {
        4 || 'SSD' => true,
        3 || 'HDD' => false,
        _ => null,
      },
      storageNvme: busType == 17 || busType == 'NVMe' ? true : (busType == null ? null : false),
      storageInterface: switch (busType) {
        17 || 'NVMe' => 'NVMe',
        11 || 'SATA' => 'SATA',
        7 || 'USB' => 'USB',
        final String other => other,
        _ => null,
      },
    );
  }

  bool _hasBattery(_PowerStatus? status) =>
      status != null && status.flag != _unknown && status.flag & _noBattery == 0 && status.percent != _unknown;

  /// SMBIOS memory type codes.
  String? _memoryType(Object? code) => switch (code) {
    20 => 'DDR',
    21 => 'DDR2',
    24 => 'DDR3',
    26 => 'DDR4',
    27 => 'LPDDR',
    28 => 'LPDDR2',
    29 => 'LPDDR3',
    30 => 'LPDDR4',
    34 => 'DDR5',
    35 => 'LPDDR5',
    _ => null,
  };
}

typedef _PowerStatus = ({int acLine, int flag, int percent, int secondsLeft});

/// The few kernel32 / iphlpapi calls the monitor needs.
final class _Win32 {
  // MIB_IF_ROW2 layout (x64).
  static const _rowSize = 1352;
  static const _rowTableOffset = 8;
  static const _typeOffset = 1128;
  static const _flagsOffset = 1152;
  static const _inOctetsOffset = 1208;
  static const _outOctetsOffset = 1280;
  static const _softwareLoopback = 24;
  static const _hardwareInterface = 0x1;
  static const _filterInterface = 0x2;

  final _kernel32 = DynamicLibrary.open('kernel32.dll');
  final _iphlpapi = DynamicLibrary.open('iphlpapi.dll');

  late final _globalMemoryStatusEx = _kernel32
      .lookupFunction<Int32 Function(Pointer<Uint8>), int Function(Pointer<Uint8>)>('GlobalMemoryStatusEx');
  late final _getSystemTimes = _kernel32
      .lookupFunction<
        Int32 Function(Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>),
        int Function(Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>)
      >('GetSystemTimes');
  late final _getTickCount64 = _kernel32.lookupFunction<Uint64 Function(), int Function()>('GetTickCount64');
  late final _getDiskFreeSpaceEx = _kernel32
      .lookupFunction<
        Int32 Function(Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>),
        int Function(Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>)
      >('GetDiskFreeSpaceExW');
  late final _getSystemPowerStatus = _kernel32
      .lookupFunction<Int32 Function(Pointer<Uint8>), int Function(Pointer<Uint8>)>('GetSystemPowerStatus');
  late final _getIfTable2 = _iphlpapi
      .lookupFunction<Uint32 Function(Pointer<Pointer<Uint8>>), int Function(Pointer<Pointer<Uint8>>)>('GetIfTable2');
  late final _freeMibTable = _iphlpapi.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
    'FreeMibTable',
  );

  int uptimeMillis() => _getTickCount64();

  /// MEMORYSTATUSEX: dwLength, dwMemoryLoad, ullTotalPhys (@8), ullAvailPhys (@16), …
  ({int used, int total})? memory() {
    final status = calloc<Uint8>(64);
    try {
      status.cast<Uint32>().value = 64;
      if (_globalMemoryStatusEx(status) == 0) {
        return null;
      }
      final total = (status + 8).cast<Uint64>().value;
      final available = (status + 16).cast<Uint64>().value;
      return (used: total - available, total: total);
    } finally {
      calloc.free(status);
    }
  }

  /// 100 ns ticks; kernel time includes idle time.
  ({int busy, int total})? cpuTicks() {
    final times = calloc<Uint64>(3);
    try {
      if (_getSystemTimes(times, times + 1, times + 2) == 0) {
        return null;
      }
      final idle = times[0];
      final total = times[1] + times[2];
      return (busy: total - idle, total: total);
    } finally {
      calloc.free(times);
    }
  }

  ({int total, int free})? diskSpace(String path) {
    final directory = path.toNativeUtf16();
    final values = calloc<Uint64>(3);
    try {
      if (_getDiskFreeSpaceEx(directory, values, values + 1, values + 2) == 0) {
        return null;
      }
      return (total: values[1], free: values[0]);
    } finally {
      calloc
        ..free(directory)
        ..free(values);
    }
  }

  /// SYSTEM_POWER_STATUS: ACLineStatus, BatteryFlag, BatteryLifePercent,
  /// SystemStatusFlag (bytes), BatteryLifeTime (@4, seconds).
  _PowerStatus? powerStatus() {
    final status = calloc<Uint8>(12);
    try {
      if (_getSystemPowerStatus(status) == 0) {
        return null;
      }
      return (acLine: status[0], flag: status[1], percent: status[2], secondsLeft: (status + 4).cast<Uint32>().value);
    } finally {
      calloc.free(status);
    }
  }

  /// Bytes in / out of the physical adapters (not loopback or the filter
  /// layers Windows stacks on each adapter, which would count it again).
  ({int rx, int tx})? networkBytes() {
    final table = calloc<Pointer<Uint8>>();
    try {
      if (_getIfTable2(table) != 0) {
        return null;
      }
      final base = table.value;
      try {
        final count = base.cast<Uint32>().value;
        var rx = 0;
        var tx = 0;
        for (var i = 0; i < count; i++) {
          final row = base + _rowTableOffset + i * _rowSize;
          final flags = row[_flagsOffset];
          if ((row + _typeOffset).cast<Uint32>().value == _softwareLoopback ||
              flags & _hardwareInterface == 0 ||
              flags & _filterInterface != 0) {
            continue;
          }
          rx += (row + _inOctetsOffset).cast<Uint64>().value;
          tx += (row + _outOctetsOffset).cast<Uint64>().value;
        }
        return (rx: rx, tx: tx);
      } finally {
        _freeMibTable(base.cast());
      }
    } finally {
      calloc.free(table);
    }
  }
}

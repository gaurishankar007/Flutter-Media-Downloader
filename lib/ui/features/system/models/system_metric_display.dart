import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/battery_charge_state.dart';
import 'package:media_tool/domain/models/battery_health.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_hardware.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/speed_test_result.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';

/// Name, icon and values of a [SystemMetric] as the strip and page show them.
extension SystemMetricDisplay on SystemMetric {
  String get label => switch (this) {
    .memory => SystemMessages.memory,
    .cpu => SystemMessages.cpu,
    .gpu => SystemMessages.gpu,
    .network => SystemMessages.network,
    .storage => SystemMessages.storage,
    .battery => SystemMessages.battery,
  };

  String get body => switch (this) {
    .memory => SystemMessages.memoryBody,
    .cpu => SystemMessages.cpuBody,
    .gpu => SystemMessages.gpuBody,
    .network => SystemMessages.networkBody,
    .storage => SystemMessages.storageBody,
    .battery => SystemMessages.batteryBody,
  };

  /// The description when the card has no live load, only hardware facts.
  String bodyFor({required bool live}) => switch (this) {
    .cpu when !live => SystemMessages.cpuInfoBody,
    .gpu when !live => SystemMessages.gpuInfoBody,
    _ => body,
  };

  IconData get icon => switch (this) {
    .memory => Symbols.memory_alt_rounded,
    .cpu => Symbols.memory_rounded,
    .gpu => Symbols.view_in_ar_rounded,
    .network => Symbols.swap_vert_rounded,
    .storage => Symbols.storage_rounded,
    .battery => Symbols.battery_full_rounded,
  };

  /// Load as 0–1 for the gauge metrics; null for the others or before a reading.
  double? fractionOf(SystemSample? sample) => switch (this) {
    .memory => sample?.memoryFraction,
    .cpu => _percentToFraction(sample?.cpuPercent),
    .gpu => _percentToFraction(sample?.gpuPercent),
    .network || .storage || .battery => null,
  };

  static double? _percentToFraction(double? percent) => percent == null ? null : percent / 100;
}

/// Text for live values; [SystemMessages.pending] until there's a reading.
abstract final class SystemFormat {
  static final _grouped = NumberFormat.decimalPattern();
  static final _oneDecimal = NumberFormat('0.0');

  /// Design capacity, full charge and charge left, each only when known.
  static List<(String, String)> batteryCapacity(BatteryStatus battery) => [
    if (battery.designCapacityMah case final mah?) (SystemMessages.batteryDesignCapacity, _mah(mah)),
    if (battery.fullChargeCapacityMah case final mah?) (SystemMessages.batteryFullCapacity, _mah(mah)),
    if (battery.remainingCapacityMah case final mah?) (SystemMessages.batteryRemaining, _mah(mah)),
  ];

  static String _mah(int mah) => SystemMessages.mah(_grouped.format(mah));

  static List<(String, String)> cpu(DeviceHardware? hardware) => [
    if (hardware?.cpuName case final name?) (SystemMessages.cpuProcessor, name),
    if (hardware?.cpuCores case final cores?) (SystemMessages.cpuCores, '$cores'),
    if (hardware?.cpuThreads case final threads?) (SystemMessages.cpuThreads, '$threads'),
    if (hardware != null && hardware.cpuClusterCores.length > 1)
      (SystemMessages.cpuLayout, SystemMessages.coreLayout(hardware.cpuClusterCores)),
    if (hardware?.cpuMaxFrequencyMhz case final mhz?)
      (SystemMessages.cpuMaxClock, SystemMessages.ghz(_oneDecimal.format(mhz / 1000))),
  ];

  static List<(String, String)> gpu(DeviceHardware? hardware) => [
    if (hardware?.gpuName case final name?) (SystemMessages.gpuName, name),
    if (hardware?.gpuCores case final cores?) (SystemMessages.gpuCores, '$cores'),
  ];

  static List<(String, String)> memory(DeviceHardware? hardware) => [
    if (hardware?.memoryType case final type?) (SystemMessages.memoryType, type),
    if (hardware?.memoryManufacturer case final maker?) (SystemMessages.memoryManufacturer, maker),
    if (hardware?.memorySpeedMhz case final mhz?) (SystemMessages.memoryClock, SystemMessages.mhz(mhz)),
  ];

  static List<(String, String)> drive(DeviceHardware? hardware) {
    final type = switch ((hardware?.storageNvme, hardware?.storageSolidState)) {
      (true, _) => SystemMessages.storageNvmeSsd,
      (_, true) => SystemMessages.storageSsd,
      (_, false) => SystemMessages.storageHardDrive,
      _ => null,
    };
    final interface = hardware?.storageInterface;
    return [
      if (hardware?.storageModel case final model?) (SystemMessages.storageDrive, model),
      if (type ?? interface case final shown?)
        (
          SystemMessages.storageType,
          type != null && interface != null ? SystemMessages.storageTypeWithInterface(type, interface) : shown,
        ),
    ];
  }

  /// Read, write and (RAM) copy speed; empty before the test ran.
  static List<(String, String)> speedTest(SpeedTestResult? result) => [
    if (result != null) ...[
      (SystemMessages.speedRead, FormatUtils.speed(result.readBytesPerSecond)),
      (SystemMessages.speedWrite, FormatUtils.speed(result.writeBytesPerSecond)),
      if (result.copyBytesPerSecond case final copy?) (SystemMessages.speedCopy, FormatUtils.speed(copy)),
    ],
  ];

  static String fraction(double? value) => value == null ? SystemMessages.pending : SystemMessages.percent(value * 100);

  /// `FormatUtils.speed` rounds anything below 1 KB up; an idle link reads 0.
  static String speed(double? bytesPerSecond) => switch (bytesPerSecond) {
    null => SystemMessages.pending,
    < 512 => SystemMessages.idleSpeed,
    final value => FormatUtils.speed(value),
  };

  static String? memoryDetail(SystemSample? sample) => switch ((sample?.memoryUsedBytes, sample?.memoryTotalBytes)) {
    (final used?, final total?) => SystemMessages.memoryOf(FormatUtils.bytes(used), FormatUtils.bytes(total)),
    _ => null,
  };

  static String bytes(int? bytes) => bytes == null ? SystemMessages.pending : FormatUtils.bytes(bytes);

  /// "1.2 GB · 0.5%"; a share under 1% reads "<1%".
  static String appShare(DeviceStorage? storage) => switch ((storage?.appBytes, storage?.appFraction)) {
    (final bytes?, final fraction?) => SystemMessages.appShare(
      FormatUtils.bytes(bytes),
      fraction > 0 && fraction < 0.01 ? SystemMessages.underOnePercent : SystemMessages.percent(fraction * 100),
    ),
    _ => SystemMessages.pending,
  };

  /// Null when the state is unknown (the row is hidden).
  static String? batteryState(BatteryStatus battery) => switch (battery.state) {
    .charging => SystemMessages.batteryCharging,
    .full => SystemMessages.batteryFull,
    .discharging => SystemMessages.batteryDischarging,
    .notCharging => SystemMessages.batteryNotCharging,
    BatteryChargeState.unknown => null,
  };

  /// Condition (Android), capacity left (macOS) or both; null when neither is known.
  static String? batteryHealthSummary(BatteryStatus battery) =>
      switch ((batteryHealth(battery.health), battery.healthPercent)) {
        (final condition?, final percent?) => SystemMessages.batteryHealthWithPercent(
          condition,
          SystemMessages.percent(percent),
        ),
        (final condition?, null) => condition,
        (null, final percent?) => SystemMessages.percent(percent),
        (null, null) => null,
      };

  static String? batteryHealth(BatteryHealth? health) => switch (health) {
    .good => SystemMessages.healthGood,
    .overheat => SystemMessages.healthOverheat,
    .dead => SystemMessages.healthDead,
    .overVoltage => SystemMessages.healthOverVoltage,
    .failure => SystemMessages.healthFailure,
    .cold => SystemMessages.healthCold,
    null => null,
  };

  /// Time remaining with its label: until empty when on battery, until full when charging.
  static (String label, String value)? batteryTime(BatteryStatus battery) =>
      switch ((battery.minutesRemaining, battery.state)) {
        (final minutes?, .charging) => (SystemMessages.batteryTimeToFull, SystemMessages.hoursMinutes(minutes)),
        (final minutes?, .discharging) => (SystemMessages.batteryTimeLeft, SystemMessages.hoursMinutes(minutes)),
        _ => null,
      };
}

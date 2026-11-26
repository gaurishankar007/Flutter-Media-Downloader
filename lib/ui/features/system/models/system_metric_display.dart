import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/battery_charge_state.dart';
import 'package:media_tool/domain/models/battery_health.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
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

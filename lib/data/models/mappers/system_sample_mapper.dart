import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';

/// Raw platform counters → [SystemSample], [DeviceStorage] and
/// [BatteryStatus]. CPU load and network speed come from the difference
/// between two readings.
abstract final class SystemSampleMapper {
  /// Readings further apart than this (the monitor was paused) give no rates.
  static const _maxGapMillis = 5000;

  /// The supported metrics, in [SystemMetric] declaration order.
  static List<SystemMetric> metrics(SystemCapabilitiesMsg msg) => [
    for (final metric in SystemMetric.values)
      if (switch (metric) {
        .network => msg.network,
        .battery => msg.battery,
        .memory => msg.memory,
        .cpu => msg.cpu,
        .gpu => msg.gpu,
        .storage => msg.storage,
      })
        metric,
  ];

  /// Null when the volume couldn't be read.
  static DeviceStorage? storage(SystemStorageMsg msg) => switch ((msg.totalBytes, msg.freeBytes)) {
    (final total?, final free?) when total > 0 => DeviceStorage(totalBytes: total, freeBytes: free.clamp(0, total)),
    _ => null,
  };

  /// Null when there's no battery data (no battery, simulator).
  static BatteryStatus? battery(SystemBatteryMsg msg) => switch (msg.levelPercent) {
    final level? => BatteryStatus(
      levelPercent: level.clamp(0, 100),
      state: switch (msg.state) {
        .charging => .charging,
        .full => .full,
        .discharging => .discharging,
        .notCharging => .notCharging,
        .unknown => .unknown,
      },
      temperatureCelsius: msg.temperatureCelsius,
      health: switch (msg.health) {
        .good => .good,
        .overheat => .overheat,
        .dead => .dead,
        .overVoltage => .overVoltage,
        .failure => .failure,
        .cold => .cold,
        .unknown || null => null,
      },
      minutesRemaining: msg.minutesRemaining,
      healthPercent: switch (msg.healthPercent) {
        final percent? when percent > 0 => percent.clamp(0, 100).toDouble(),
        _ => null,
      },
      cycleCount: switch (msg.cycleCount) {
        final cycles? when cycles >= 0 => cycles,
        _ => null,
      },
    ),
    null => null,
  };

  static SystemSample fromMsg(SystemSampleMsg current, SystemSampleMsg? previous) {
    final elapsedMillis = previous == null ? 0 : current.uptimeMillis - previous.uptimeMillis;
    final comparable = elapsedMillis > 0 && elapsedMillis <= _maxGapMillis;
    final seconds = elapsedMillis / 1000;

    double? perSecond(int? now, int? before) => switch ((now, before)) {
      // A negative delta means a 32-bit counter wrapped or an interface went away.
      (final now?, final before?) when comparable && now >= before => (now - before) / seconds,
      _ => null,
    };

    double? cpuPercent() {
      final busy = _delta(current.cpuBusyTicks, previous?.cpuBusyTicks);
      final total = _delta(current.cpuTotalTicks, previous?.cpuTotalTicks);
      if (!comparable || busy == null || total == null || total <= 0 || busy < 0) {
        return null;
      }
      return (busy / total * 100).clamp(0, 100);
    }

    return SystemSample(
      memoryUsedBytes: current.memoryUsedBytes,
      memoryTotalBytes: current.memoryTotalBytes,
      cpuPercent: cpuPercent(),
      gpuPercent: current.gpuPercent?.clamp(0, 100),
      downloadBytesPerSecond: perSecond(current.networkRxBytes, previous?.networkRxBytes),
      uploadBytesPerSecond: perSecond(current.networkTxBytes, previous?.networkTxBytes),
    );
  }

  static int? _delta(int? now, int? before) => now != null && before != null ? now - before : null;
}

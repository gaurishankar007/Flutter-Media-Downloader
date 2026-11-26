import 'package:media_downloader/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_downloader/domain/models/system_metric.dart';
import 'package:media_downloader/domain/models/system_sample.dart';

/// Raw platform counters → [SystemSample]. CPU load and network speed come
/// from the difference between two readings.
abstract final class SystemSampleMapper {
  /// Readings further apart than this (the monitor was paused) give no rates.
  static const _maxGapMillis = 5000;

  static List<SystemMetric> metrics(SystemCapabilitiesMsg msg) => [
    if (msg.memory) .memory,
    if (msg.cpu) .cpu,
    if (msg.gpu) .gpu,
    if (msg.network) .network,
  ];

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

import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/system_metric.dart';
import 'package:media_downloader/domain/models/system_sample.dart';

/// Live device stats (RAM, CPU, GPU, network) read on the device only.
abstract interface class SystemMonitorRepository {
  /// What this device reports, once known (cached after the first call).
  List<SystemMetric>? get knownMetrics;

  /// The metrics this device supports, in display order.
  FutureList<SystemMetric> metrics();

  /// Reads the counters now; rates compare with the previous reading.
  FutureData<SystemSample> sample();
}

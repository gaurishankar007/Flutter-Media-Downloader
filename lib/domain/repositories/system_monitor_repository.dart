import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';

/// Live device stats (RAM, CPU, GPU, network, storage, battery) read on the device only.
abstract interface class SystemMonitorRepository {
  /// What this device reports, once known (cached after the first call).
  List<SystemMetric>? get knownMetrics;

  /// The metrics this device supports, in display order.
  FutureList<SystemMetric> metrics();

  /// Reads the counters now; rates compare with the previous reading.
  FutureData<SystemSample> sample();

  /// Space on the app's volume, or null when it can't be read. The app's own
  /// folder is measured again only when [measureAppFiles] is true (it walks
  /// every file); otherwise the last measurement is reused.
  FutureData<DeviceStorage?> storage({bool measureAppFiles = false});

  /// The battery now, or null when the device reports none.
  FutureData<BatteryStatus?> battery();
}

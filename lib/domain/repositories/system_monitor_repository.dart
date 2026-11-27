import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/speed_test.dart';
import 'package:media_tool/domain/models/speed_test_result.dart';
import 'package:media_tool/domain/models/system_profile.dart';
import 'package:media_tool/domain/models/system_sample.dart';

/// Live device stats (RAM, CPU, GPU, network, storage, battery), hardware
/// facts and speed tests, read on the device only.
abstract interface class SystemMonitorRepository {
  /// What this device reports, once known (cached after the first call).
  SystemProfile? get knownProfile;

  /// The cards this device supports, in display order, with its hardware facts.
  FutureData<SystemProfile> profile();

  /// Reads the counters now; rates compare with the previous reading.
  FutureData<SystemSample> sample();

  /// Space on the app's volume, or null when it can't be read. The app's own
  /// folder is measured again only when [measureAppFiles] is true (it walks
  /// every file); otherwise the last measurement is reused.
  FutureData<DeviceStorage?> storage({bool measureAppFiles = false});

  /// The battery now, or null when the device reports none.
  FutureData<BatteryStatus?> battery();

  /// The last result of [test] in this app session, if it ran.
  SpeedTestResult? lastSpeedTest(SpeedTest test);

  /// Runs [test] (a few seconds). The storage test needs twice its file size free.
  FutureData<SpeedTestResult> runSpeedTest(SpeedTest test);
}

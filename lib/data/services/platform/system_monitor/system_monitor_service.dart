import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';

/// Raw device counters: through Pigeon on Android, iOS and macOS, read in Dart
/// on Windows and Linux. Methods throw; the repository calls them inside
/// `ErrorHandler`. See docs/features/system.md.
abstract interface class SystemMonitorService {
  Future<SystemCapabilitiesMsg> capabilities();

  Future<SystemSampleMsg> sample();

  Future<SystemStorageMsg> storage();

  Future<SystemBatteryMsg> battery();

  Future<SystemHardwareMsg> hardware();
}

/// Kotlin: `system/`; Swift: `Runner/SystemMonitor/` on iOS and macOS.
@LazySingleton(as: SystemMonitorService, env: [PlatformEnv.android, PlatformEnv.ios, PlatformEnv.macos])
final class PigeonSystemMonitorService implements SystemMonitorService {
  final _api = SystemMonitorHostApi();

  @override
  Future<SystemCapabilitiesMsg> capabilities() => _api.capabilities();

  @override
  Future<SystemSampleMsg> sample() => _api.sample();

  @override
  Future<SystemStorageMsg> storage() => _api.storage();

  @override
  Future<SystemBatteryMsg> battery() => _api.battery();

  @override
  Future<SystemHardwareMsg> hardware() => _api.hardware();
}

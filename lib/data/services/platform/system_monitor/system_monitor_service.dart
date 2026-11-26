import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';

/// Raw device counters through Pigeon (Kotlin: `system/`, Swift:
/// `Runner/SystemMonitor/` on iOS and macOS). Methods throw; the repository
/// calls them inside `ErrorHandler`.
abstract interface class SystemMonitorService {
  Future<SystemCapabilitiesMsg> capabilities();

  Future<SystemSampleMsg> sample();
}

@LazySingleton(as: SystemMonitorService)
final class SystemMonitorServiceImpl implements SystemMonitorService {
  final _api = SystemMonitorHostApi();

  @override
  Future<SystemCapabilitiesMsg> capabilities() => _api.capabilities();

  @override
  Future<SystemSampleMsg> sample() => _api.sample();
}

import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's own version, from the platform.
abstract interface class AppInfoService {
  /// `1.0.0 (1)`.
  Future<String> version();
}

@LazySingleton(as: AppInfoService)
final class AppInfoServiceImpl implements AppInfoService {
  @override
  Future<String> version() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}

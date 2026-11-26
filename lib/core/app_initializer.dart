import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:media_tool/config/injector/injector.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/domain/repositories/settings_repository.dart';

/// Prepares everything the first screen needs. See docs/architecture/app_startup.md.
abstract final class AppInitializer {
  static bool _dependenciesConfigured = false;

  /// Returns `false` when the app can't start (shows StartupErrorApp).
  static Future<bool> initializeApp() async {
    try {
      // Steps 1–2 run once, even when Retry calls this again.
      if (!_dependenciesConfigured) {
        await configureDependencies(environment: PlatformEnv.current);
        ErrorHandlerProvider.I.configureErrorHandlers();
        _dependenciesConfigured = true;
      }

      // Step 3. A failed settings read is already recorded; start with defaults.
      await (GetIt.I<AppDirectories>().init(), GetIt.I<SettingsRepository>().load()).wait;
      return true;
    } catch (error, stackTrace) {
      debugPrint('AppInitializer failed: $error\n$stackTrace');
      return false;
    }
  }
}

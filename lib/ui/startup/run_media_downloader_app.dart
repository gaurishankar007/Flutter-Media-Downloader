import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/app_initializer.dart';
import 'package:media_downloader/ui/application.dart';
import 'package:media_downloader/ui/startup/startup_error_app.dart';

/// Initialises the app, then runs it, or the startup error screen with Retry.
Future<void> runMediaDownloaderApp() async {
  final initialized = await AppInitializer.initializeApp();
  runApp(
    initialized
        ? const ProviderScope(child: MediaDownloaderApp())
        : const StartupErrorApp(onRetry: runMediaDownloaderApp),
  );
}

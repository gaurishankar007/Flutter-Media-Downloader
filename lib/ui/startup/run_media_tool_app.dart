import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/app_initializer.dart';
import 'package:media_tool/ui/application.dart';
import 'package:media_tool/ui/startup/startup_error_app.dart';

/// Initialises the app, then runs it, or the startup error screen with Retry.
Future<void> runMediaToolApp() async {
  final initialized = await AppInitializer.initializeApp();
  runApp(
    initialized
        ? const ProviderScope(child: MediaToolApp())
        : const StartupErrorApp(onRetry: runMediaToolApp),
  );
}

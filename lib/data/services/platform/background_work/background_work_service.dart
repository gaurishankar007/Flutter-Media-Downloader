import 'package:media_downloader/domain/models/background_activity.dart';

/// Keeps downloads running while the app is in the background (Android's
/// foreground service + notification). Methods throw; repositories call them
/// inside `ErrorHandler`. See docs/engine/android_engine.md#running-in-the-background.
abstract interface class BackgroundWorkService {
  /// Job ids whose Cancel was tapped in the notification.
  Stream<String> get cancelRequests;

  /// Asks for the notification permission where one exists (Android 13+).
  Future<void> requestNotificationPermission();

  /// Starts the service or updates its notification.
  Future<void> show(BackgroundActivity activity);

  Future<void> stop();
}

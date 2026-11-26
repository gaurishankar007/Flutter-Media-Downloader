import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/background_activity.dart';

/// Keeps downloads alive in the background and shows their notification.
abstract interface class BackgroundWorkRepository {
  /// Job ids whose Cancel was tapped in the notification.
  Stream<String> get cancelRequests;

  /// Asks for the notification permission (Android 13+), once per run.
  FutureVoid requestNotificationPermission();

  /// Shows [activity], or stops the background work when it's null.
  FutureVoid update(BackgroundActivity? activity);
}

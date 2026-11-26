// Pigeon input: keeps classic field + constructor syntax (see CLAUDE.md).
// Regenerate: dart run pigeon --input lib/config/pigeon/background_work_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/clients/platform/background_work_api.g.dart',
    dartPackageName: 'media_tool',
    kotlinOut: 'android/app/src/main/kotlin/com/gss/mediatool/background/BackgroundWorkApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.gss.mediatool.background'),
  ),
)
/// What the download notification shows.
class BackgroundWorkMsg {
  BackgroundWorkMsg({required this.jobId, required this.title, required this.activeCount, this.percent});

  /// The job the notification's Cancel action stops.
  String jobId;
  String title;

  /// Null while the percentage is unknown (indeterminate bar).
  int? percent;

  /// Jobs running or waiting.
  int activeCount;
}

/// Android's foreground service that keeps downloads running in the
/// background. See docs/engine/android_engine.md#running-in-the-background.
@HostApi()
abstract class BackgroundWorkHostApi {
  /// Starts the service, or updates its notification when it's running.
  void update(BackgroundWorkMsg work);

  /// Stops the service and removes the notification.
  void stop();
}

/// Calls from the notification back into Dart.
@FlutterApi()
abstract class BackgroundWorkFlutterApi {
  /// The notification's Cancel action was tapped.
  void cancelRequested(String jobId);
}

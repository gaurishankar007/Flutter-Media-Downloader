// Pigeon input: keeps classic field + constructor syntax (see CLAUDE.md).
// Regenerate: dart run pigeon --input lib/config/pigeon/media_engine_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/clients/platform/media_engine_api.g.dart',
    dartPackageName: 'media_downloader',
    kotlinOut: 'android/app/src/main/kotlin/com/gss/mediadownloader/engine/MediaEngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.gss.mediadownloader.engine'),
    swiftOut: 'ios/Runner/Engine/MediaEngineApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'MediaEnginePigeonError'),
  ),
)
/// What `init` found: yt-dlp version and the video encoders ffmpeg has.
class EngineInfoMsg {
  EngineInfoMsg({required this.ytDlpVersion, required this.encoders});

  String ytDlpVersion;
  List<String> encoders;
}

enum EngineEventKind {
  /// One stdout line (progress, stage markers).
  line,

  /// Finished successfully. Payload: empty.
  done,

  /// Failed. Payload: stderr.
  error,

  /// Stopped by `cancel`.
  cancelled,
}

/// One event of a running job.
class EngineEventMsg {
  EngineEventMsg({required this.jobId, required this.kind, required this.payload});

  String jobId;
  EngineEventKind kind;
  String payload;
}

/// Runs yt-dlp and ffmpeg. Arguments are always built in Dart; the native
/// side only runs them. See docs/engine/android_engine.md.
@HostApi()
abstract class MediaEngineHostApi {
  /// Unpacks Python, yt-dlp and ffmpeg (slow on first launch).
  // `init` is a keyword in Swift.
  @async
  @SwiftFunction('initialize()')
  EngineInfoMsg init();

  /// Runs yt-dlp with [args] and returns its stdout (the `-J` JSON).
  @async
  String probe(List<String> args);

  /// Starts yt-dlp for [jobId]; progress and the result arrive as events.
  void startDownload(String jobId, List<String> args);

  /// Starts ffmpeg for [jobId]; progress and the result arrive as events.
  void startFfmpeg(String jobId, List<String> args);

  /// Stops [jobId]'s process. Returns whether one was running.
  bool cancel(String jobId);

  /// Updates yt-dlp. Returns the version after the update.
  @async
  String updateYtDlp();
}

@EventChannelApi()
abstract class MediaEngineEventsApi {
  EngineEventMsg engineEvents();
}

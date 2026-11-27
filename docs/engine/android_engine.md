# Android Engine

> Status: implemented (not yet tested on real devices). Dart: `android_media_engine.dart` (also used on iOS). Kotlin: `android/app/src/main/kotlin/com/gss/mediatool/engine/MediaEngine.kt`.

## Library

`io.github.junkfood02.youtubedl-android`, modules `library` and `ffmpeg`, version **0.18.1** (`android/app/build.gradle.kts`). It bundles Python + yt-dlp + ffmpeg inside the APK and supports in-app yt-dlp updates. Look up the current version on Maven Central before bumping it.

youtubedl-android runs Python and ffmpeg as executables from `nativeLibraryDir`, so native libraries must be extracted on install:

- `AndroidManifest.xml`: `android:extractNativeLibs="true"`.
- `build.gradle.kts`: `packaging.jniLibs.useLegacyPackaging = true`, and `keepDebugSymbols` for `libpython.zip.so` / `libffmpeg.zip.so` (zip archives named `.so`; stripping them fails).

## Bridge

Pigeon (`lib/config/pigeon/media_engine_api.dart`; Kotlin output in `engine/MediaEngineApi.g.kt`, Swift output in `ios/Runner/Engine/MediaEngineApi.g.swift`):

```dart
@HostApi()
abstract class MediaEngineHostApi {
  @async @SwiftFunction('initialize()') EngineInfoMsg init(); // yt-dlp version + video encoders
  @async String probe(List<String> args);                     // stdout of yt-dlp -J
  void startDownload(String jobId, List<String> args);
  void startFfmpeg(String jobId, List<String> args);
  bool cancel(String jobId);                                  // whether a process was running
  @async String updateYtDlp();
}

@EventChannelApi()
abstract class MediaEngineEventsApi {
  EngineEventMsg engineEvents(); // jobId, kind (line | done | error | cancelled), payload
}
```

- One event channel carries every job's events; `AndroidMediaEngine` filters them by job id and subscribes before starting the job, so the first lines aren't missed.
- Kotlin runs each job on `Dispatchers.IO` in a `SupervisorJob` scope and posts events on the main thread.
- yt-dlp: `YoutubeDL.execute(request, jobId) { _, _, line -> ... }`. Only the raw `line` is forwarded; the Dart parser (shared with iOS and macOS) does the rest.
- ffmpeg: the bundled `libffmpeg.so` is started as a `ProcessBuilder` (with `LD_LIBRARY_PATH` set to youtubedl-android's unpacked ffmpeg libs), stdout lines are forwarded, stderr is drained on its own thread and its last 4000 characters become the error payload.
- `init()` calls `YoutubeDL.getInstance().init(context)` and `FFmpeg.getInstance().init(context)`, then reads `ffmpeg -hide_banner -encoders` once to report the video encoders (see [ffmpeg Recipes](ffmpeg_recipes.md#encoder-choice)).

## Running in the Background

Downloads keep going when the app is in the background or the screen is off.

- A **foreground service** (`DownloadService`, type `dataSync`) runs while any job is active. Its one notification shows the active job's title and percent (indeterminate while unknown) and a **Cancel** action.
- Dart drives it through Pigeon `lib/config/pigeon/background_work_api.dart`: `BackgroundWorkHostApi.update(work)` starts the service or updates the notification, `stop()` ends it; `BackgroundWorkFlutterApi.cancelRequested(jobId)` sends the notification's Cancel back to Dart. `DownloadQueueNotifier` calls `BackgroundWorkRepository.update` on every state change and stops it when the queue is idle.
- On iOS and macOS `NoopBackgroundWorkService` stands in.
- `POST_NOTIFICATIONS` is requested (`permission_handler`) when a download is added on Android 13+. If it's denied, downloads still run; only the notification is hidden.
- Android 15+ limits `dataSync` services per day; on `onTimeout` the service stops itself.
- Swiping the app away from recents ends the Dart side, so the queue stops tracking jobs.

## Storage

Files go to the app's own folder (`AppDirectories`, under Application Support). Nothing goes to MediaStore until the user taps **Save to Photos** (gallery, via `gal`) or **Save to Files** (SAF `ACTION_CREATE_DOCUMENT` through Pigeon `file_export_api.dart`, Kotlin `export/FileExporter.kt`). See [Library](../features/library.md).

## Quality Strategy on Android

- iPhone-compatible on and the tier has H.264: select `avc1` video + `m4a` audio so the result is only a remux into MP4. Fast and no quality loss.
- No H.264 at that height (YouTube 1440p / 4K): download the best streams into MKV, then re-encode. Encoders are tried in order: `hevc_mediacodec` (if `ffmpeg -encoders` lists it), then `libx264 -preset veryfast`. This is slow on phones; the preview warns about it.
- iPhone-compatible off: keep the original codecs (MP4 if they fit, else MKV), no re-encode.

## Known Limits

- The app grows by roughly 30–70 MB per ABI because of Python + ffmpeg; the released APK is universal (all ABIs), so it carries every copy.
- gallery-dl isn't included. Photo posts go through the Dart extractors; see [Photo Extractors](../extractors/photo_extractors.md).

# Android Engine

> Status: planned (v1 step 1). Dart: `android_media_engine.dart`. Kotlin: `android/app/src/main/kotlin/.../engine/`.

## Library

`io.github.junkfood02.youtubedl-android`, modules `library` and `ffmpeg` (optionally `aria2c`). It bundles Python + yt-dlp + ffmpeg inside the APK and supports in-app yt-dlp updates. **Look up the current version on Maven Central before adding it**, and follow its README for the required Gradle/manifest settings (at the time of planning: `android:extractNativeLibs="true"` and legacy JNI packaging, so the bundled Python can be extracted).

## Bridge

Pigeon (`lib/config/pigeon/media_engine_api.dart`):

```dart
@HostApi()
abstract class MediaEngineHostApi {
  @async EngineInfoMsg init();
  @async String probe(String url, String? cookiesPath);          // raw yt-dlp JSON
  @async void startDownload(String jobId, List<String> args);
  @async void startFfmpeg(String jobId, List<String> args);
  @async String probeFile(String path);                          // raw ffprobe JSON
  @async void cancel(String jobId);
  @async String updateYtDlp();
}

@EventChannelApi()
abstract class MediaEngineEvents {
  EngineEventMsg progress(); // jobId, kind (line | progress | done | error), payload
}
```

- Kotlin runs each request on `Dispatchers.IO` in a coroutine scope tied to the job id.
- youtubedl-android's callback gives `(progress, etaInSeconds, line)`. The Kotlin side forwards the raw `line` so the Dart progress parser (shared with macOS) does the work.
- `init()` calls `YoutubeDL.getInstance().init(context)` and `FFmpeg.getInstance().init(context)`, then reads `ffmpeg -encoders` once to report which encoders exist (see [ffmpeg Recipes](ffmpeg_recipes.md#encoder-choice)).

## Running in the Background

Downloads must keep going when the app is in the background or the screen is off.

- A **foreground service** (`dataSync` type) runs while any job is active, with one notification showing the active job's title and percent, and a **Cancel** action.
- The service stops itself when the queue is empty.
- `POST_NOTIFICATIONS` is requested the first time a download starts on Android 13+. If it's denied, downloads still run; only the notification is hidden.

## Storage

Files go to the app's own folder (`filesDir/downloads`). Nothing goes to MediaStore until the user taps **Save to Photos** (gallery, via `gal`) or **Save to Files** (SAF). See [Core Services](../core/core_services.md#platform-services).

## Quality Strategy on Android

- ≤ 1080p with iPhone-compatible on: select `avc1` video + `m4a` audio so the result only needs a remux (`-c copy`). Fast and no quality loss.
- 1440p / 4K: YouTube only has VP9/AV1, so re-encode with the best encoder the bundled ffmpeg has. Check `ffmpeg -encoders`: `hevc_mediacodec` if present, else `libx264`. This is slow on phones; the preview warns about it.
- iPhone-compatible off: keep the original codecs in MKV/MP4, no re-encode.

## Known Limits

- The app grows by roughly 30–70 MB per ABI because of Python + ffmpeg, so first install and build times are longer.
- gallery-dl isn't included. The Dart photo extractors cover photos; see [Photo Extractors](../extractors/photo_extractors.md#fallback-gallery-dl).

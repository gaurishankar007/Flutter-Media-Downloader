# iOS Engine

> Status: implemented (not yet tested on a real device). Dart: the shared `android_media_engine.dart` (same Pigeon API). Swift / Objective-C: `ios/Runner/Engine/`.

## Why it's different

iOS apps can't start subprocesses, so yt-dlp and ffmpeg can't run as binaries. Both run **inside the app process**:

- **Python:** CPython **3.13**, embedded with BeeWare's `Python-Apple-support` XCFramework (release `3.13-b18`). yt-dlp is the official **zipapp** (pure Python, imported straight from the zip) and runs through its own CLI entry point, `yt_dlp.main(argv)`, with the same argument list `YtDlpArgsBuilder` builds for Android and macOS.
- **ffmpeg:** **FFmpegKit 8.1.3 `full-gpl`** (VideoToolbox, libmp3lame, libx264, libvpx) as XCFrameworks, from the maintained `sk3llo/ffmpeg_kit_flutter` fork (the original ffmpeg-kit was retired in 2025). It's linked into the app and called in-process.

## Bridge

The same Pigeon API as Android (`media_engine_api.dart`), with the Swift output in `ios/Runner/Engine/MediaEngineApi.g.swift`. `AppDelegate` registers `IosMediaEngine` as the host API and event stream handler. On the Dart side, `AndroidMediaEngine` is registered for both `PlatformEnv.android` and `PlatformEnv.ios`, so there's no iOS-specific Dart engine.

| File | What it does |
| --- | --- |
| `IosMediaEngine.swift` | Pigeon host API; starts Python, runs jobs on their own threads (16 MB stack, Python needs more than a secondary thread's 512 KB), forwards lines, background time, update |
| `MDPythonRuntime.h/.m` | Starts the interpreter (`PYTHONHOME` = bundled `python/`), registers the `_mdengine` native module (`emit`, `ffmpeg`, `async_raise`) and calls shim functions |
| `MDFFmpeg.h/.m` | Runs FFmpegKit sessions per job id: stdout lines out, cancel, sync runs for `-encoders` and for yt-dlp's ffmpeg/ffprobe calls |
| `python/engine_shim.py` | The only Python we write (below) |

### yt-dlp in Python

`engine_shim.py`:

- `init(bundled_zip, update_zip)` / `reload()` import yt-dlp from the updated zipapp if it loads, else the bundled one, and return its version.
- `probe(argv_json)` runs `yt_dlp.main(argv)` and returns captured stdout (the `-J` JSON).
- `download(job_id, argv_json)` runs `yt_dlp.main(argv)` with `sys.stdout` routed per thread: each complete line goes to Swift (`_mdengine.emit`) and on to Dart as an `EngineLine`. So iOS produces the **same raw stdout lines** (`[MD]` progress, `[Merger]`, …) as the other platforms, and the same Dart parser reads them. Returns `done` / `error` (stderr tail) / `cancelled`.
- `cancel(job_id)` raises `JobCancelled` (a `BaseException`, so yt-dlp's `except Exception` can't swallow it) in the job's thread through `async_raise`.
- yt-dlp runs ffmpeg/ffprobe for merging and audio extraction by starting a process. The shim replaces yt-dlp's `Popen` with `_InProcessPopen`, which runs `ffmpeg` / `ffprobe` through FFmpegKit in-process (and fails like a missing program for anything else).
- Environment set by Swift before start: `SSL_CERT_FILE` → bundled `certifi/cacert.pem` (Python on iOS has no CA bundle), `XDG_CACHE_HOME` → Caches.

There is **no JavaScript runtime** on iOS, so YouTube formats that need yt-dlp's JS challenge solving can be missing.

### Cancel

yt-dlp: `cancel` in the shim (or, while Python is still starting, the job is marked and never handed to yt-dlp). A running merge / audio extraction is stopped by cancelling its FFmpegKit session. Standalone ffmpeg jobs: `MDFFmpeg.cancelJob`.

## Packaging

### Fetch script

`ios/Frameworks/` is not committed. Run once after cloning (and again to refresh):

```bash
ios/scripts/fetch_engine.sh
```

It downloads `Python.xcframework` (BeeWare), the FFmpegKit XCFrameworks (`ffmpegkit`, `libavcodec`, `libavdevice`, `libavfilter`, `libavformat`, `libavutil`, `libswresample`, `libswscale`, each checked against the release's `checksums.json`), the yt-dlp zipapp (checked against `SHA2-256SUMS`) and the `certifi` wheel into `ios/Frameworks/`.

### Build phase

`ios/scripts/install_engine.sh` runs as the **Install Python engine** build phase (after Resources). It stops the build with an error if the fetch script hasn't been run. It copies Python's standard library (dropping `test`, `idlelib`, `tkinter` and other unused parts), turns each Python binary module into a signed framework (an iOS requirement), and copies the shim, `yt-dlp.zip` and `certifi` into `Runner.app/engine/`. It reimplements BeeWare's `utils.sh` because that one breaks on paths with spaces and on multi-arch simulator builds (it merges per-arch modules with `lipo`). Unsigned builds (simulator, `--no-codesign`) are signed ad hoc.

The engine adds roughly 285 MB to the app.

### Updates

`updateYtDlp` downloads `https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp` into `Application Support/engine/yt-dlp.zip` and calls the shim's `reload()`. See [Media Engine: Updates](media_engine.md#updates).

## Running on your device

- Deployment target iOS 15.0.
- Change the bundle id from `com.gss.mediatool` to your own, then in Xcode → Runner → *Signing & Capabilities* pick your team (automatic signing).
- A free Apple ID installs for 7 days; a paid developer account for about a year.
- `Info.plist`: `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`.

## Storage and Saving

- Output goes to Application Support (`AppDirectories`). At launch `BackupExclusion.swift` marks `downloads/`, `thumbnails/`, `cookies/` and `engine/` as excluded from iCloud / device backup (downloads are large, thumbnails and the engine can be rebuilt, cookies must never leave the device).
- **Save to Photos:** `gal` (PHPhotoLibrary, add-only permission).
- **Save to Files:** `UIDocumentPickerViewController(forExporting:)` through Pigeon `file_export_api.dart` (Swift `Export/FileExporter.swift`).

## Background

There's no foreground service on iOS (`NoopBackgroundWorkService`). iOS gives an app roughly 30 seconds after it goes to the background. Each job (download or ffmpeg) asks for that time with `beginBackgroundTask`; if it runs out, the job is cancelled and reported as failed ("iOS stopped the job in the background"), so the user can retry. Long background downloads would need `URLSession` background transfers, which yt-dlp can't use; not planned.

## Encoder

The encoder list comes from FFmpegKit's `-encoders`; `hevc_videotoolbox` (hardware) is the first choice for iPhone-compatible re-encodes, then `h264_videotoolbox`, then `libx264`. See [ffmpeg Recipes](ffmpeg_recipes.md#encoder-choice).

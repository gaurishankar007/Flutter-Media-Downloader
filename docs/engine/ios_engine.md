# iOS Engine

> Status: planned (v1 step 5, built last: the hardest platform). Dart: `ios_media_engine.dart`. Swift: `ios/Runner/Engine/`.

## Why it's different

iOS apps can't start subprocesses, so yt-dlp and ffmpeg can't run as binaries. Both run **inside the app process**:

- **Python:** CPython 3.13+ (official iOS support), embedded with BeeWare's `Python-Apple-support` XCFramework. yt-dlp runs as a Python module (`yt_dlp.YoutubeDL`), not a command.
- **ffmpeg:** linked as a library. `ffmpeg_kit` was retired in 2025, so use a maintained fork or build ffmpeg XCFrameworks ourselves with `videotoolbox` and `libmp3lame` enabled.

## Bridge

Same Pigeon API as Android (`media_engine_api.dart`), Swift implementation.

### yt-dlp in Python

A small Python shim (`ios/Runner/Engine/python/engine_shim.py`) is the only Python we write:

```python
from yt_dlp import YoutubeDL, parse_options

def download(job_id, argv, emit):
    opts = parse_options(argv).ydl_opts   # same args as Android/macOS
    opts["progress_hooks"] = [lambda d: emit(job_id, d)]
    opts["postprocessor_hooks"] = [lambda d: emit(job_id, d)]
    with YoutubeDL(opts) as ydl:
        ydl.download([argv[-1]])
```

- `parse_options(argv)` turns the same argument list `YtDlpArgsBuilder` makes for the other platforms into `YoutubeDL` options, so there's one code path for building downloads. (Check that `parse_options` is still exported from `yt_dlp` when implementing.)
- The progress hook dicts are forwarded to Dart as JSON and mapped by the same `JobProgress` mapper.
- yt-dlp calls ffmpeg for merging and audio extraction by running a command. On iOS that can't work, so the shim registers an `ffmpeg` location that is a tiny Python wrapper calling the linked ffmpeg library in-process. (Prototype this first: it is the riskiest part of the iOS engine.)
- Python runs on its own background thread with the GIL; one interpreter for the app's lifetime.

### Cancel

The progress hook checks `cancelled[job_id]` and raises `DownloadCancelled`; ffmpeg sessions are cancelled through the library's cancel call.

## Packaging

- The Python standard library and `yt_dlp` (and optionally `gallery_dl`) ship as resources; binary extension modules must be packaged as frameworks to be signed, following the CPython iOS guide.
- yt-dlp updates: download the official `yt-dlp` zipapp release into Application Support and put it first on `sys.path` (see [Media Engine: Updating](media_engine.md#updating-yt-dlp)).

## Running on your device

- Change the bundle id from `com.example.mediaDownloader` to your own, then in Xcode → Runner → *Signing & Capabilities* pick your team (automatic signing).
- A free Apple ID installs for 7 days; a paid developer account for about a year.
- `Info.plist`: `NSPhotoLibraryAddUsageDescription` ("Save downloaded videos and photos to your Photos library.").
- Make sure the Python and ffmpeg XCFrameworks and every Python binary module are embedded and signed (see [Packaging](#packaging)).

## Storage and Saving

- Output goes to Application Support `downloads/` (excluded from iCloud backup).
- **Save to Photos:** `gal` (PHPhotoLibrary, add-only permission).
- **Save to Files:** `UIDocumentPickerViewController(forExporting:)` through Pigeon `FileExportService`.

## Background

iOS gives an app roughly 30 seconds after it goes to the background. Each job asks for that time with `beginBackgroundTask`; if it runs out, the job is marked `failed` with **Retry** (partial download resumes where yt-dlp can). The UI says "Keep the app open for long downloads." Long background downloads would need `URLSession` background transfers, which yt-dlp can't use; not planned.

## Encoder

`hevc_videotoolbox` (hardware) for iPhone-compatible re-encodes; see [ffmpeg Recipes](ffmpeg_recipes.md).

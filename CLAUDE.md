# Media Downloader & Converter — Project Brief

> Paste this whole file into a new Claude Code session (run from the project folder)
> as the starting prompt. It contains every decision made so far.

## Goal

A Flutter app for **Android, iOS and macOS** that:

1. Downloads videos from **YouTube, Facebook, Instagram, Threads, X/Twitter and TikTok** by pasting a link.
2. Downloads **photos** too: Instagram photo and carousel posts, TikTok photo posts (slideshows), Threads/X images.
3. Saves either **video (MP4)**, **audio (MP3)** or **photos (JPG)** from any of those sites.
4. Converts local files: video ↔ video (MP4/MKV/WebM/MOV), video → MP3/M4A, image ↔ image (JPG/PNG/WebP/HEIC).
5. Produces **iPhone-compatible** output by default (HEVC or H.264 video + AAC audio in MP4), so files play in the iPhone Photos app.

Personal-use tool. Not distributed via Google Play or the App Store (both reject YouTube downloaders).

## Distribution (decided)

| Platform | How it ships |
|---|---|
| Android | Signed APK, shared directly / GitHub Releases / F-Droid-style. User enables "install unknown apps". |
| iOS | Paid Apple Developer account: development/ad-hoc install on registered devices (≤100, ~1 year), or TestFlight **internal** testers only (90-day builds). No App Store, no external TestFlight. |
| macOS | Developer ID signed + notarized DMG, outside the Mac App Store, **not sandboxed**. |

## Architecture

One Flutter app with a shared UI + a platform-specific download engine behind a single Dart interface.

```
lib/
  core/
    engine/media_engine.dart        # abstract interface (below)
    engine/engine_android.dart      # MethodChannel -> Kotlin
    engine/engine_ios.dart          # MethodChannel -> Swift (embedded Python)
    engine/engine_macos.dart        # dart:io Process -> bundled binaries
    models/                         # MediaInfo, FormatOption, DownloadJob, ConvertJob
    platform_detect.dart            # URL -> youtube | facebook | instagram | threads | x | tiktok | unknown
    extractors/
      threads_extractor.dart        # custom Threads support (videos + images)
      instagram_photo_extractor.dart# Instagram photo/carousel posts (yt-dlp is video-only)
      tiktok_photo_extractor.dart   # TikTok photo posts / slideshows (yt-dlp is video-only)
  features/
    download/                       # paste link -> preview -> choose MP4/MP3 + quality -> queue
    convert/                        # pick/drag local file -> choose target format
    queue/                          # progress, cancel, open/share/show-in-folder
    settings/                       # default quality, iPhone-compatible toggle, output folder, engine update
```

### Engine interface

```dart
abstract class MediaEngine {
  Future<void> init();                                   // unpack/update yt-dlp etc.
  Future<MediaInfo> probe(String url);                   // title, thumbnail, duration, formats
  Stream<JobProgress> download(DownloadRequest req);     // percent, speed, ETA, state, output path
  Stream<JobProgress> convert(ConvertRequest req);       // local file conversion
  Future<void> cancel(String jobId);
  Future<String> updateYtDlp();                          // returns new version
}
```

### Per-platform engine

- **Android:** library `io.github.junkfood02.youtubedl-android` (modules: `library`, `ffmpeg`; optionally `aria2c`). It bundles Python + yt-dlp + ffmpeg and supports `YoutubeDL.updateYoutubeDL()`. Look up the current version on Maven Central before adding it. Kotlin side runs requests on a background coroutine and streams progress back over an `EventChannel`. Save output to MediaStore (Downloads / Movies / Music) so it shows up in the gallery and file managers.
- **iOS:** apps cannot start subprocesses. Embed CPython (3.13+ supports iOS officially; use BeeWare's `Python-Apple-support` XCFramework) and call `yt_dlp.YoutubeDL` **as a Python module**, using `progress_hooks` for progress. ffmpeg must be linked as a library: `ffmpeg_kit` was retired in 2025, so use a maintained fork or build ffmpeg XCFrameworks with `videotoolbox` and `libmp3lame` enabled. Save to Photos (PHPhotoLibrary) or share via the Files app / share sheet. Hardest platform: build it last.
- **macOS:** bundle the standalone `yt-dlp_macos` binary and a static `ffmpeg` / `ffprobe` in `Contents/Resources`, and run them with `Process`. Parse `--newline` progress lines. Turn off App Sandbox. yt-dlp updates itself with `yt-dlp -U` into Application Support.

## Site support (verified with yt-dlp 2026.11.23)

| Site | Status |
|---|---|
| YouTube | ✅ incl. 4K (VP9/AV1 only above 1080p) and Shorts |
| Facebook | ✅ videos and Reels; private posts need cookies |
| Instagram | ✅ posts, Reels; Stories need cookies; `instagram:user` (whole profile) is **currently broken** |
| X / Twitter | ✅ tweets with video, Spaces (audio) |
| Threads | ❌ **no yt-dlp extractor**. Write `threads_extractor.dart`: fetch the post HTML, read the `og:video` / `og:image` meta or the embedded JSON for the media URLs, then download and pass them through the same ffmpeg step. Expect it to break when Meta changes the page; keep it isolated and easy to fix. |
| TikTok videos | ✅ `TikTok` and `vm.tiktok` (short links) work in yt-dlp, and so do `tiktok:user` and `tiktok:collection`. `tiktok:sound`, `tiktok:tag` and `tiktok:effect` are **currently broken**. |
| TikTok photo posts | ❌ in yt-dlp. ✅ in **gallery-dl** 1.32.21 (`tiktok:post` and `tiktok:vmpost` handle `/@user/photo/<id>` and vm.tiktok links). |

Logged-in content: support importing cookies (a Netscape cookies.txt file, or on macOS `--cookies-from-browser`). Never send cookies anywhere except the target site.

## Photo posts (yt-dlp does not do images)

yt-dlp only extracts video. On an Instagram photo post it fails with `There is no video in this post`. Photos need their own route:

**Primary route: Dart extractors (works on all three platforms, no extra native code).**
- **Instagram** (tested 2026-11-25 on a public photo post, worked without login): fetch `https://www.instagram.com/p/<shortcode>/embed/captioned/` with a normal browser User-Agent. Take the `<img class="EmbeddedMediaImage">` element and pick the widest entry in its `srcset` (gave 1152×1440 WebP). For carousels, also look for every slide in the embed page's JSON. Strip tracking query params (`?fqnt=…`, `?igsh=…`) from pasted links first.
- **TikTok photo posts:** fetch the post page. The `<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__">` JSON contains `imagePost.images[].imageURL.urlList[]`; take the first URL of each image, in order. The post's music is in the same JSON (`music.playUrl`). Resolve `vm.tiktok.com` short links by following redirects first. (Check this JSON path against a live post when implementing; TikTok changes it now and then.)
- **Threads / X images:** `og:image` / embedded JSON (Threads), and yt-dlp's metadata or the tweet's media for X.

**Fallback: gallery-dl** (Python, same idea as yt-dlp but for images).
- macOS: bundle it, or use the Homebrew/pip version during development.
- iOS: install it as a pure-Python package alongside yt-dlp in the embedded Python.
- Android: youtubedl-android does not include it. Only add it if the Dart extractors aren't enough (it would mean switching to Chaquopy, a tool for running Python in Android apps, or packaging gallery-dl into the app's Python).
- gallery-dl's Instagram support needs a login (tested: `401 Unauthorized` without cookies). Use it for Instagram only when the user has imported cookies.

**Photo output:** convert WebP/HEIC to **JPG** by default (quality ~92) so files open everywhere, with an option to keep the original. Save numbered files for carousels/slideshows: `<user> <postid> 01.jpg`, `02.jpg`, …

**Optional for TikTok slideshows:** "Save as video": turn the images + `music.playUrl` audio into an MP4 with ffmpeg (each image ~3 s, or spread evenly across the audio length).

## Proven yt-dlp / ffmpeg settings

These were tested on real downloads during planning.

**Best video ≤ chosen height, merged:**
```
yt-dlp -f "bv*[height<=2160]+ba/b" --merge-output-format mkv -o "%(title)s [%(height)sp].%(ext)s" URL
```

**Make it iPhone-compatible (HEVC + AAC MP4).** YouTube 4K/1440p only comes as VP9/AV1, so it has to be re-encoded:
```
ffmpeg -i in.mkv -c:v hevc_videotoolbox -q:v 65 -tag:v hvc1 -pix_fmt yuv420p \
       -c:a aac -b:a 192k -movflags +faststart out.mp4
```
- `-tag:v hvc1` is required, or the Apple Photos app refuses the file.
- Use `hevc_videotoolbox` on macOS/iOS. On Android, prefer selecting `avc1`+`m4a` formats when ≤1080p (then only remux: `-c copy`). For 4K, re-encode with whatever encoder the bundled ffmpeg has (check `ffmpeg -encoders`; MediaCodec `hevc_mediacodec` if available, else `libx264`).
- Optimisation: if the chosen formats are already H.264/HEVC + AAC, skip re-encoding and just remux.

**MP3:**
```
yt-dlp -f ba -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata -o "%(title)s.%(ext)s" URL
```

**Filenames:** titles can be long, non-Latin (e.g. Hindi) or full of hashtags. Strip `#tags`, trim to about 80 chars, and keep Unicode (`--restrict-filenames` is off; sanitise only the characters that are illegal on the filesystem).

## v1 scope (build in this order)

1. Flutter project + shared UI + `MediaEngine` interface + **Android engine**. Paste link → preview → MP4 (Best/4K/1080p/720p) or MP3 → progress → saved to gallery/Downloads. YouTube, Facebook, Instagram, X, TikTok videos.
2. Photo extractors (Instagram photos/carousels, TikTok photo posts) + Threads extractor. A pasted link automatically picks the video or photo route.
3. Local file converter (video/audio/image).
4. macOS engine (bundled binaries).
5. iOS engine (embedded Python + ffmpeg library).
6. Settings: iPhone-compatible toggle (on by default), default quality, cookies import, "Update engine" button + check for updates on launch.

## Non-goals / guardrails

- No backend server: everything runs on the device.
- No Play Store / App Store submission.
- Show a one-time notice that users are responsible for having the rights to what they download.
- Don't store or upload user cookies or download history anywhere off-device.

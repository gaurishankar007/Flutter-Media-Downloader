# Media Downloader

A Flutter app for **Android, iOS and macOS** that downloads videos, audio and photos from social platforms, keeps them in its own library, and converts or shrinks media files. Everything runs on the device: no server.

> Personal-use tool, built and run from source on your own devices; it isn't distributed. Users are responsible for having the rights to what they download.

## Features (planned)

### Download
- **Video → MP4** from YouTube (up to 4K), Facebook, Instagram, Threads, X/Twitter and TikTok
- **Audio → MP3** from any of those sites (320 kbps, with title and cover art)
- **Photos → JPG** from Facebook photo posts and albums, Instagram photo/carousel posts, TikTok photo posts (slideshows), Threads and X
- **Preview before downloading:** paste a link and see the thumbnail, title, uploader and duration. Videos can be played in the app before you download them (when the site gives a direct stream URL). Photo posts show every image, and you pick which ones to save.
- **Quality choice:** Best / 4K / 1440p / 1080p / 720p / 480p for video, with the size estimate for each, and 320 / 192 / 128 kbps for MP3
- **iPhone-compatible output** by default (HEVC/H.264 + AAC in MP4) so files play in the Photos app
- Download queue with progress, speed, ETA and cancel, plus a one-tap engine update when sites change
- **Share and Remove on the download page:** when a download finishes, its card on the download page gets **Share** (system share sheet, e.g. to save to Photos/Files or send to another app) and **Remove** (deletes it from the app after a confirm). Since the share sheet can't always tell the app whether you saved the file, removing is your call here: share first, then tap Remove.

### Library (the app's own download folder)
- Everything the app downloads or converts is saved to the **app's own folder** first, not straight to the gallery.
- A **Library** page shows all of it in one place: grid of thumbnails, filter by Videos / Audio / Photos and by site, sort by date or size, search by title. Tap to play or view.
- Each item has:
  - **Save to Photos** (iOS/macOS Photos app, Android gallery)
  - **Save to Files** (Files app on iOS, a folder you pick on Android/macOS)
  - **Share** (system share sheet)
  - **Delete**
- After **Save to Photos** or **Save to Files** succeeds, the app asks: *"Saved to Photos. Remove it from the app to free up space?"* with **Keep** / **Remove** (and a "don't ask again" option, set in Settings). Items you keep are marked as saved.
- Storage used by the library is shown in Settings, with a "clear saved items" button.

### Convert & compress
- **Import from:** the app's Library, the Photos library / gallery, or the file system (Files app / file picker / drag and drop on macOS)
- **Video ↔ video:** MP4, MKV, WebM, MOV
- **Video → audio:** MP3, M4A
- **Image ↔ image:** JPG, PNG, WebP, HEIC
- **Reduce size (video):** lower resolution (1080p / 720p / 480p), quality presets (High / Medium / Small), optional "aim for about N MB"
- **Reduce size (image):** resize (longest side or %), JPG/WebP quality slider, strip metadata
- Shows the original size and the result size before you keep it. Output goes to the Library like a download.

## Site support

| Site | Video | Photos | Engine |
|---|---|---|---|
| YouTube | ✅ up to 4K, Shorts, MP3 | n/a | yt-dlp |
| Facebook | ✅ videos and Reels | ✅ photo posts and albums (custom extractor; private posts need cookies) | yt-dlp + Dart |
| Instagram | ✅ posts and Reels (Stories need login) | ✅ custom extractor | yt-dlp + Dart |
| X / Twitter | ✅ videos, Spaces audio | ✅ | yt-dlp |
| TikTok | ✅ videos, short links | ✅ photo posts | yt-dlp + Dart / gallery-dl |
| Threads | ✅ custom extractor | ✅ custom extractor | Dart |

## How it works

One shared Flutter UI talks to a `MediaEngine` interface. Each platform has its own engine:

| Platform | Engine |
|---|---|
| Android | [youtubedl-android](https://github.com/JunkFood02/youtubedl-android) (Python + yt-dlp + ffmpeg in the app) via a platform channel (Flutter's bridge to native code) |
| iOS | Embedded Python (3.13+) running yt-dlp as a module, plus ffmpeg as a library |
| macOS | Bundled `yt-dlp_macos`, `ffmpeg`, `ffprobe` run as processes (app not sandboxed) |

Photo posts (which yt-dlp doesn't support) go through small Dart extractors in `lib/data/services/remote/extractors/`, with gallery-dl as a fallback.

The converter and compressor reuse the same ffmpeg that every engine already ships for merging and iPhone re-encoding, so they need no extra native engine.

**Storage:** downloads land in the app's own folder (Application Support / app documents directory), and a small local database indexes them for the Library page (title, source URL, site, type, size, thumbnail, saved-to-Photos flag). Nothing leaves the device.

## Design

Dark-first media-app look (in the style of Spotify, Linear and Arc) with one vivid violet → pink "Aurora" gradient for primary actions and progress, big rounded thumbnails, Plus Jakarta Sans + Inter, and a full light theme. Bottom nav on phones, sidebar on tablets and macOS. Details: [docs/design/design_system.md](docs/design/design_system.md).

## Architecture

Feature-first **MVVM** with Riverpod (same architecture as the vAIolin app): UI (Views + Notifiers) → optional use cases → repositories → services (local / platform / remote). get_it + injectable for DI, auto_route for routing, drift for the local database, a sealed `DataState` for results and one `ErrorHandler` for errors.

```
lib/
  config/        # DI (per-platform environments), Pigeon inputs
  core/          # database, http client, DataState, errors, messages, app folders, utils
  data/          # repositories + services: local (drift), platform (MediaEngine per OS, gallery, export), remote (photo extractors)
  domain/        # models, repository contracts, use cases (ResolveLink, DownloadMedia)
  routing/       # auto_route, tab shell
  ui/
    core/        # theme tokens, base widgets, base notifiers, ToastUtil
    features/    # home, download, library, convert, settings
macos/Runner/Resources/bin/   # bundled yt-dlp_macos, ffmpeg, ffprobe (not committed)
```

## Documentation

Every module is described in [`docs/`](docs/), laid out like the vAIolin docs. Start with [docs/architecture/architecture.md](docs/architecture/architecture.md) (it has a map of all docs).

| Folder | What's in it |
|---|---|
| `architecture/` | Layers and structure, app startup, development (SDK, lints, codegen) |
| `design/` | Design system: colours, type, spacing, motion, components, screen layouts |
| `core/` | Routing, error handling, app messages, local database, core services |
| `engine/` | MediaEngine interface; Android, iOS, macOS engines; tested yt-dlp/ffmpeg recipes; site support |
| `extractors/` | Instagram, TikTok, Facebook photo extractors, Threads, gallery-dl fallback |
| `features/` | Download, Library, Convert & Compress, Settings |
| `utils/` | Packages, troubleshooting |

Rules for working on the code (and the product brief) are in [CLAUDE.md](CLAUDE.md).

## Getting started

Requirements: Flutter (stable), Xcode (iOS/macOS), Android Studio / Android SDK.

```bash
flutter pub get
flutter run -d android     # or: -d ios, -d macos
```

**macOS build:** first put these binaries in `macos/Runner/Resources/bin/`:
- `yt-dlp_macos`: https://github.com/yt-dlp/yt-dlp/releases
- `ffmpeg` and `ffprobe`: static macOS builds
- optional: `gallery-dl`

**iOS install on your own devices:** open `ios/Runner.xcworkspace` in Xcode, set your team under *Signing & Capabilities*, register the device, then run. With a paid developer account the install lasts about a year; with a free account, 7 days.

## Roadmap

1. Shared UI + `MediaEngine` + **Android engine**: YouTube, Facebook, Instagram, X, TikTok videos; MP4/MP3 with quality choice and preview. **Library page** with Save to Photos / Save to Files / Share / Delete and the "remove from app?" prompt.
2. Photo extractors (Facebook, Instagram, TikTok) + Threads extractor
3. Converter and compressor: video/audio/image formats, size reduction, import from Library / Photos / Files
4. macOS engine
5. iOS engine
6. Settings: iPhone-compatible toggle, default quality, cookie import, storage use, engine updates

**Later (if they turn out to be a lot of work):** HEIC *output* on Android, exact target-size video compression (two-pass), batch conversion of many files at once.

## Before release

- Change the app ID from `com.example.media_downloader` to your own (Android `applicationId`, iOS/macOS bundle identifier).

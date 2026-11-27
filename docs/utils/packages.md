# Packages

> What `pubspec.yaml` declares today. Look up the current version of a package on pub.dev before adding or bumping it; don't copy version numbers from here.

## App

| Package | Why |
| --- | --- |
| `material_ui` | Material widgets (decoupled from the Flutter SDK). `cupertino_ui` isn't needed yet. |
| `hooks_riverpod` | State management (Notifiers as ViewModels), with flutter_hooks integration |
| `flutter_hooks` | Local widget state (controllers, animations) |
| `get_it`, `injectable` | Dependency injection |
| `auto_route` | Routing with the tab shell |
| `drift`, `drift_flutter` | Local database |
| `dio` | HTTP for extractors, photo/video downloads and the GitHub release check (`SiteHttpClient`, `MediaFileDownloader`, `EngineReleaseService`) |
| `html` | Parsing extractor pages (Facebook) |
| `path_provider`, `path` | App folders, path handling |
| `file_picker` | Import from Files and from Photos (media picker), cookies.txt import, the Save to Files dialog on macOS, Windows and Linux |
| `gal` | Save to Photos / gallery (Android, iOS, macOS, Windows; Linux copies the file itself) |
| `share_plus` | Share sheet |
| `permission_handler` | Android notification permission for the download foreground service |
| `video_player` | Preview playback and the Library viewer (no Linux implementation) |
| `video_player_win` | The Windows `video_player` implementation (Media Foundation), registered automatically |
| `ffi` | `calloc` and UTF-16 strings for the Win32 calls (Windows system monitor and speed tests) |
| `flutter_image_compress` | Image convert / compress, photos → JPG, thumbnails (Android, iOS, macOS; Windows and Linux use ffmpeg) |
| `flutter_sliding_toast` | Toasts through `ToastUtil` |
| `package_info_plus` | App version in About |
| `uuid` | Job, item and error-log ids |
| `intl` | Sizes, dates, durations |
| `equatable` | Value equality for states and models |
| `material_symbols_icons` | Material Symbols Rounded |

Native, not Dart packages: `youtubedl-android` `library` + `ffmpeg` and `kotlinx-coroutines-android` / `androidx.core` (Android Gradle), BeeWare `Python.xcframework` + FFmpegKit full-gpl + yt-dlp zipapp + certifi (iOS, fetched by `ios/scripts/fetch_engine.sh`), `yt-dlp_macos` + static `ffmpeg` / `ffprobe` (+ optional `deno`) (macOS, fetched by `macos/scripts/fetch_engine_binaries.sh`), `yt-dlp.exe` / `yt-dlp_linux` + BtbN GPL `ffmpeg` / `ffprobe` (+ optional `deno`) (Windows and Linux, fetched by `windows/scripts/fetch_engine.ps1` and `linux/scripts/fetch_engine_binaries.sh`). See the [engine docs](../engine/media_engine.md).

## Dev

| Package | Why |
| --- | --- |
| `build_runner`, `injectable_generator`, `auto_route_generator`, `drift_dev` | Code generation |
| `pigeon` | Native bridges: engine, file export, background work, system monitor |
| `flutter_launcher_icons`, `flutter_native_splash` | App icon and native splash from `assets/icon/` (see [Development](../architecture/development.md#app-icon-and-splash)) |
| `leancode_lint` | Lints |

There are no test packages: the project has no automated tests.

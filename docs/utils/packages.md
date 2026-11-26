# Packages

> Planned set. Look up the current version of each on pub.dev when adding it; don't copy version numbers from here.

## App

| Package | Why |
| --- | --- |
| `material_ui`, `cupertino_ui` | Material / Cupertino widgets (decoupled from the Flutter SDK) |
| `flutter_riverpod` | State management (Notifiers as ViewModels) |
| `flutter_hooks` | Local widget state (controllers, animations) |
| `get_it`, `injectable` | Dependency injection |
| `auto_route` | Routing with tab shell |
| `drift`, `drift_flutter` | Local database |
| `dio` | HTTP for extractors and photo downloads (replaces `http`) |
| `html` | Parsing extractor pages |
| `path_provider`, `path` | App folders, path handling |
| `file_picker` | Import from Files, cookies.txt import |
| `image_picker` | Import from Photos / gallery |
| `gal` | Save to Photos / gallery (Android, iOS, macOS) |
| `share_plus` | Share sheet |
| `permission_handler` | Photos add-only, notifications |
| `video_player` | Preview playback and Library viewer |
| `cached_network_image` | Remote thumbnails in the preview |
| `flutter_image_compress` | Image convert / compress / WebP→JPG, thumbnails |
| `flutter_sliding_toast` | Toasts through `ToastUtil` |
| `url_launcher` | Open source link, help pages |
| `package_info_plus` | App version in About |
| `uuid` | Job ids |
| `intl` | Sizes, dates, durations |
| `equatable` | Value equality for states and models |
| `material_symbols_icons` | Material Symbols Rounded |

Native, not Dart packages: `youtubedl-android` (Gradle), CPython `Python-Apple-support` + ffmpeg XCFrameworks (iOS), bundled binaries (macOS). See the [engine docs](../engine/media_engine.md).

## Dev

| Package | Why |
| --- | --- |
| `build_runner`, `injectable_generator`, `auto_route_generator`, `drift_dev` | Code generation |
| `pigeon` | Native bridge for the engine and file export |
| `leancode_lint` | Lints (replaces `flutter_lints`) |
| `flutter_launcher_icons`, `flutter_native_splash` | Icon and splash |

## Changes from the current `pubspec.yaml`

- Remove `http` (use `dio`), `flutter_lints` (use `leancode_lint`). Keep `cupertino_icons` only if Cupertino icons get used.
- Everything else in the table is new.

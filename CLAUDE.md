# Media Tool — Claude Code Rules (CLAUDE.md)

> These rules apply to Claude Code working in this project. Follow them strictly.

---

## 1. Project Identity

- **App:** Media Tool. A Flutter app that downloads videos, audio and photos from YouTube, Facebook, Instagram, Threads, X/Twitter and TikTok, keeps them in its own Library, and converts or compresses media files.
- **Architecture:** Feature-first MVVM with Riverpod, get_it/injectable, auto_route and drift. See `docs/architecture/architecture.md`.
- **Platforms:** Android, iOS, macOS, Windows, Linux. No web, no flavors.
- **Entry point:** `lib/main.dart`. Package name: `media_tool`.
- **Personal-use tool, released on GitHub.** No app stores. Tagged versions publish a signed universal Android APK, an unsigned macOS DMG, a Windows zip and a Linux tarball to GitHub Releases (`.github/workflows/release.yml`; see `docs/architecture/development.md#releases`). iOS is run from source only. **To release, ALWAYS follow the `release` skill** (`.claude/skills/release/SKILL.md`): toolchain parity check → validate → version → approved notes → tag → watch CI.

---

## 2. Mandatory Rules (Never Violate)

- **BEFORE** any task, read the **relevant** docs in `docs/` (only what the task needs). Start from the Docs Map in `docs/architecture/architecture.md`.
- **NEVER** update `docs/` as part of a code change without **asking the user first**. Make the change, stop, and let the user try it. Only after they say it's final, ask whether to update the docs, and do it in one pass. Approval to *implement* is not approval to write docs. Exception: a task that is itself a docs task.
- **NO automated tests.** The project has no test suite; verify changes with `flutter analyze` and by running the app.
- **ALWAYS** write code for the SDK installed on this machine (Flutter 3.50.1 / Dart 3.14 as of 2026-11-25) with its newest idioms. If a newer SDK is installed than `pubspec.yaml` allows, tell the user and offer to upgrade before writing feature code.
- **NEVER** use relative imports. Always `package:media_tool/...`.
- **NEVER** write business logic in widgets or Views. It belongs in Notifiers, use cases and repositories.
- **NEVER** add platform-specific code under `lib/ui/`. Route it through `lib/data/services/platform/` (Pigeon or `dart:io` `Process`).
- **NEVER** call `MediaEngine`, dio, drift or `dart:io` file APIs from Notifiers or Views. Go through repositories.
- **NEVER** send cookies anywhere except the site they belong to, and never log, upload or back them up. Nothing (cookies, history, errors) leaves the device: no backend, no analytics, no crash reporting.
- **NEVER** use `void` as the return type of `async` methods. Use `Future<void>`.
- **NEVER** add a `Co-Authored-By: Claude ...` (or similar AI-attribution) trailer to commit messages.

---

## 3. Code Style

- Single quotes; `const` wherever possible; `if`/`for`/`while` bodies on a new line; constructors first in a class; method tear-offs over lambdas.
- Short comments that only explain a non-obvious *why*.

### Modern Dart & Flutter

Details in `docs/architecture/development.md`. In short:

- **Primary constructors**, `;` for empty bodies, **dot shorthands** (`.center`, `const .all(16)`), **null-aware elements** (`[?x]`), wildcard `_`.
- **Patterns:** switch expressions, `if (x case final T y)`, `sealed` hierarchies with exhaustive `switch`, records.
- **Material/Cupertino** from `package:material_ui` / `package:cupertino_ui`, never `package:flutter/material.dart`.
- No deprecated APIs; never silence `deprecated_member_use`.
- Never edit generated files (`*.g.dart`, `*.gr.dart`, `*.config.dart`, Pigeon output). Pigeon inputs in `lib/config/pigeon/` keep classic field + constructor syntax.

---

## 4. Architecture Rules

### State Management

- All ViewModels extend `BaseNotifier` / `BaseAsyncNotifier` / `BaseStreamNotifier`; all states extend `BaseState` (`StateStatus` + `StateMessage`).
- **`copyWith` never keeps the previous `message`**: use the argument directly (`message: message`), so messages can be cleared.
- Views show `StateMessage`s with `ToastUtil` (on `flutter_sliding_toast`), never `SnackBar`.
- Each user flow runs in `runFlow('<flow label>', ...)`; surface errors with `trackFailure(dataState)` / `trackError(text)`, never a bare `ErrorMessage(...)`. Every `ErrorHandler.execute` call passes an `action:` label. See `docs/core/error_handling.md`.
- Every user-facing string lives in `lib/core/messages/app_messages.dart`. Bump `kMessagesVersion` when wording changes. See `docs/core/app_messages.md`.
- **Notifiers never show toasts, dialogs or navigate.** They set state (e.g. `pendingRemovePrompt`); the View reacts with `ref.listen`.
- `ref.listen` uses the `ref` of the widget/builder it's called in, never one captured from an outer scope.
- A Notifier that calls another notifier captures it once in `build()` (nullable field), never a lazy getter or inline `ref.read`.
- Check `ref.mounted` before touching state after an `await` in `.autoDispose` notifiers.
- Downloads and conversions are owned by **keep-alive** notifiers, so leaving a screen never cancels a job.

### UI Widgets

- **One widget per file.** Extract widgets, never `_buildX()` methods.
- Design-system widgets live in `lib/ui/core/ui/base/<category>/` and take plain props only (no Notifier/Ref).
- Colours, text styles, spacing, radius and motion come from the tokens in `lib/ui/core/themes/`. **Never write a hex colour or raw font size in a widget.** See `docs/design/design_system.md`.
- Prefer `ConsumerWidget` / `HookConsumerWidget` / `ConsumerStatefulWidget` over `StatefulWidget`.
- Promote a widget to `base/` or a feature's `widgets/` only once a second real consumer needs it.

### Dependency Injection

- `@injectable`, `@lazySingleton`, `@singleton`. Per-platform implementations use injectable environments (`PlatformEnv.android | ios | macos | windows | linux`; `PlatformEnv.desktop` lists the three desktops).
- Run `dart run build_runner build` after changing any injectable class, route or drift table.

### Data Layer

- Services return raw data (DTOs, primitives) wrapped in `ErrorHandler`; repositories map DTOs to domain models and return `DataState<T>`.
- `FutureVoid` methods return `const SuccessState.nil()` on success, never `SuccessState(data: null)`.
- yt-dlp and ffmpeg arguments are built **only** in Dart (`YtDlpArgsBuilder`, `FfmpegCommandBuilder`); platform engines only run them.
- Store file paths in the database **relative** to the app's base folder.
- Every `schemaVersion` bump gets an explicit `onUpgrade` step and an exported schema snapshot (`dart run drift_dev make-migrations`). Never delete exported schema snapshots.

---

## 5. Project Structure

```
lib/ui/features/<feature>/
    ├── models/       # UI-only models
    ├── providers/    # Notifiers
    ├── widgets/      # shared across this feature's screens
    └── views/<screen>/
        ├── <screen>_screen.dart
        └── widgets/  # this screen only

lib/data/
    ├── models/responses/   # DTOs (yt-dlp JSON, extractor pages)
    ├── repositories/       # implementations
    └── services/
        ├── local/          # drift, settings, cookies files
        ├── platform/       # MediaEngine (Android/iOS + desktop), file export, background work, system monitor, gallery, share, pickers, images
        └── remote/         # SiteHttpClient, photo extractors, MediaFileDownloader, EngineReleaseService

lib/domain/
    ├── models/             # Site, MediaInfo, FormatOption, JobProgress, LibraryItem, ...
    ├── repositories/       # abstract contracts
    └── use_cases/          # ResolveLinkUseCase, DownloadMediaUseCase, ConvertMediaUseCase
```

Full tree: `docs/architecture/architecture.md`. Features: `home` (shell, 5 tabs: Download, Library, Convert, System, Settings), `download`, `library`, `convert`, `system`, `settings`.

Widget tiers: one screen → `views/<screen>/widgets/`; several screens in one feature → `<feature>/widgets/`; several features → `lib/ui/core/ui/base/<category>/`.

---

## 6. Code Generation

```bash
dart run build_runner build                                       # routes, DI, drift
dart run pigeon --input lib/config/pigeon/media_engine_api.dart     # engine bridge (Android, iOS)
dart run pigeon --input lib/config/pigeon/file_export_api.dart      # Save to Files bridge
dart run pigeon --input lib/config/pigeon/background_work_api.dart  # Android foreground service
dart run pigeon --input lib/config/pigeon/system_monitor_api.dart   # System tab (Android, iOS, macOS)
```

Engine files aren't committed: after cloning run `macos/scripts/fetch_engine_binaries.sh`, `ios/scripts/fetch_engine.sh`, `windows/scripts/fetch_engine.ps1` or `linux/scripts/fetch_engine_binaries.sh` for the platforms you build. See `docs/architecture/development.md`.

---

## 7. Code Quality

- Lints: `leancode_lint` (configured in `analysis_options.yaml`).
- `flutter analyze` must be clean before a task is done.

---

## 8. What NOT to Do

| ❌ Don't | ✅ Do instead |
| --- | --- |
| Business logic in widgets | Notifier / use case / repository |
| Relative imports | `package:media_tool/...` |
| Hex colours / raw sizes in widgets | Theme tokens (`context.colors`, `context.text`, spacing) |
| `SnackBar` | `ToastUtil` with `StateMessage` |
| Hard-coded user text | `lib/core/messages/app_messages.dart` |
| Bare `try/catch` | `ErrorHandler.execute<T>(action: ...)` |
| Build yt-dlp/ffmpeg args in Kotlin/Swift | `YtDlpArgsBuilder` / `FfmpegCommandBuilder` in Dart |
| Notifier opens a dialog or navigates | Set state; the View reacts |
| Absolute paths in the database | Paths relative to `AppDirectories.base` |
| Send cookies or data off-device | Keep everything on the device |
| Hand-edit generated files | Change the source and regenerate |

---

## 9. Product Brief

### Goal

1. Download **videos** (MP4), **audio** (MP3) and **photos** (JPG) by pasting a link from YouTube, Facebook, Instagram, Threads, X/Twitter and TikTok. Photos: Facebook photo posts/albums, Instagram photos/carousels, TikTok photo posts (slideshows), Threads/X images, YouTube channel posts.
2. **Preview** before downloading (thumbnail, title, in-app playback when possible, all photos of a post) and pick the **quality** (Best/4K/1440p/1080p/720p/480p; MP3 320/192/128).
3. Save into the **app's own folder**; a **Library** shows everything, with Save to Photos, Save to Files, Share, Delete, and a "remove from app?" prompt after a confirmed save. Finished jobs on the Download page have **Share** and **Remove**.
4. **Convert and compress** local files (from the Library, Photos or Files): video ↔ MP4/MKV/WebM/MOV, video → MP3/M4A, image ↔ JPG/PNG/WebP/HEIC, smaller videos and images.
5. **iPhone-compatible** output by default (HEVC or H.264 + AAC in MP4, `hvc1` tag), so files play in the iPhone Photos app.

### Running on your own devices

| Platform | How it runs |
| --- | --- |
| Android | `flutter run` on your own phone or emulator. |
| iOS | `flutter run` / Xcode with your Apple ID team (free: 7-day installs; paid account: ~1 year). |
| macOS | `flutter run`; the app is **not sandboxed** because it runs bundled binaries. |
| Windows | `flutter run -d windows` on a Windows PC (x64), after `windows/scripts/fetch_engine.ps1`. |
| Linux | `flutter run -d linux` on a Linux PC (x64), after `linux/scripts/fetch_engine_binaries.sh`. No video playback. |

### Where the decisions live

| Topic | Doc |
| --- | --- |
| Engine interface, probe, progress, cancel, updates, FfmpegSlot | `docs/engine/media_engine.md` |
| Android (youtubedl-android), iOS (embedded CPython + FFmpegKit, same Dart engine as Android), macOS / Windows / Linux (one desktop engine over bundled binaries, fetch scripts) | `docs/engine/android_engine.md`, `ios_engine.md`, `desktop_engine.md`, `macos_engine.md` |
| Tested yt-dlp / ffmpeg commands, compression presets | `docs/engine/ffmpeg_recipes.md` |
| What each site supports, cookies | `docs/engine/site_support.md` |
| Instagram / TikTok / Facebook photos, Threads, X images, YouTube posts, link routing | `docs/extractors/photo_extractors.md` |
| Download page, preview, job cards, Share/Remove | `docs/features/download.md` |
| Library, Save to Photos/Files, remove prompt | `docs/features/library.md` |
| Converter and compressor | `docs/features/convert.md` |
| System tab: RAM / CPU / GPU / network monitor, hardware facts, speed tests per platform | `docs/features/system.md` |
| Settings, cookies, engine updates, About | `docs/features/settings.md` |
| Look and feel | `docs/design/design_system.md` |

### Build order (v1)

All six steps are implemented (untested on devices), plus a System tab (system monitor) and Windows and Linux builds (built in CI, untested on devices).

1. Project skeleton (architecture, theme, base widgets) + `MediaEngine` + **Android engine**. Paste → preview → MP4/MP3 with quality → progress → app folder. **Library** with Save to Photos / Save to Files / Share / Delete and the remove prompt; Share / Remove on finished downloads. YouTube, Facebook, Instagram, X, TikTok videos.
2. Photo extractors (Facebook, Instagram, TikTok) + Threads extractor. A pasted link picks the video or photo route automatically.
3. Converter + compressor, importing from Library / Photos / Files.
4. macOS engine.
5. iOS engine (hardest; last).
6. Settings: iPhone-compatible toggle, default quality, cookie import, engine update + check on launch.

Later: exact-size two-pass compression, batch conversion, HEIC output on Android if unreliable, receiving links from the share sheet.

### Guardrails

- No backend server: everything runs on the device.
- No store submission; releases go only to GitHub Releases. NEVER commit the release keystore or `android/key.properties` (the keystore lives outside the repo; CI reads it from repository secrets).
- Show a one-time notice that users are responsible for having the rights to what they download.
- Don't store or upload cookies, download history or errors anywhere off-device.

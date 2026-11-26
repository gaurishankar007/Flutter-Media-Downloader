# Development

SDK, code style, lints and code generation.

## SDK

- Installed here (2026-11-25): **Flutter 3.50.1**, **Dart 3.14**. `pubspec.yaml` requires `sdk: ^3.14.0`.
- Write code for the installed SDK using its newest idioms. If a newer SDK is installed later, say so and offer to upgrade before writing feature code (the `flutter-modernize` skill does this).

## Modern Dart & Flutter

Idioms:

- **Primary constructors:** `class const JobCard({super.key, required final DownloadJob job}) extends StatelessWidget { ... }`.
- **Empty bodies** end with `;`: `abstract class BaseNotifier<T> extends Notifier<T> with ErrorTracking;`.
- **Dot shorthands:** `mainAxisAlignment: .center`, `padding: const .all(16)`, `borderRadius: .circular(16)`.
- **Null-aware elements** `[?maybeItem]`, wildcard `_` for unused parameters.
- **Patterns:** switch expressions, `if (x case final T y)`, `sealed` hierarchies with exhaustive `switch` (e.g. `JobStage`, `DataState`), records for small multi-value returns.
- **Material/Cupertino** come from `package:material_ui` / `package:cupertino_ui`, never `package:flutter/material.dart`. (The app only needs `material_ui` today; add `cupertino_ui` when a Cupertino widget is used.)
- No deprecated APIs (`withValues(alpha:)`, not `withOpacity`).
- Never hand-edit generated files (`*.g.dart`, `*.gr.dart`, `*.config.dart`, Pigeon output). Pigeon inputs in `lib/config/pigeon/` keep classic field + constructor syntax, because Pigeon's parser needs it.

## Code Style

- Package imports only (`package:media_downloader/...`), never relative.
- Single quotes; `const` wherever possible; `if`/`for`/`while` bodies on a new line; constructors first in a class; method tear-offs over lambdas.
- `Future<void>` for async methods, never `void`.
- Short comments that explain a non-obvious *why* only.
- One widget per file; extract widgets, never `_buildX()` methods.

## Lints

`leancode_lint`, configured in `analysis_options.yaml`, plus project rules on top (package imports, `sort_constructors_first`, `avoid_void_async`, `always_put_control_body_on_new_line`, `use_declaring_parameters`, `use_null_aware_elements`, ...). `flutter analyze` must be clean before a task is done.

There is no automated test suite: verify changes with `flutter analyze` and by running the app.

## Code Generation

```bash
# Routes (auto_route), DI (injectable), database (drift)
dart run build_runner build

# Pigeon bridges (Dart + Kotlin + Swift outputs are set in each input file)
dart run pigeon --input lib/config/pigeon/media_engine_api.dart     # engine (Android Kotlin, iOS Swift)
dart run pigeon --input lib/config/pigeon/file_export_api.dart      # Save to Files (Android, iOS)
dart run pigeon --input lib/config/pigeon/background_work_api.dart  # Android foreground service
dart run pigeon --input lib/config/pigeon/system_monitor_api.dart   # System tab (Android, iOS, macOS)
```

Run `build_runner` after adding or changing any route, injectable class or drift table. Generated Dart clients land in `lib/core/clients/platform/`. `system_monitor_api.dart` writes the same Swift file to both `ios/Runner/SystemMonitor/` and `macos/Runner/SystemMonitor/`; the hand-written `SystemMonitor.swift` next to it is kept in sync by hand.

## Running

After cloning, fetch the native engine files once (they're not committed):

```bash
flutter pub get
macos/scripts/fetch_engine_binaries.sh   # macOS: yt-dlp_macos, ffmpeg, ffprobe into macos/Runner/Resources/bin/ (--with-deno, --universal)
ios/scripts/fetch_engine.sh              # iOS: Python.xcframework, FFmpegKit, yt-dlp + certifi into ios/Frameworks/
flutter run -d android                   # or: -d ios, -d macos
```

Android needs no fetch step: youtubedl-android comes from Gradle. Xcode build phases copy the fetched files into the app (`macos/scripts/bundle_engine_binaries.sh`, `ios/scripts/install_engine.sh`). Details: [macOS Engine](../engine/macos_engine.md), [iOS Engine](../engine/ios_engine.md).

VS Code: `.vscode/launch.json` has **Android (debug)**, **iOS (debug)** and **macOS (debug)** launch configurations.

## Releases

`.github/workflows/release.yml` builds and publishes a GitHub Release, which non-developers download from the repo's **Releases** page.

- **Trigger:** push a tag (`git tag v1.2.0 && git push origin v1.2.0`), or run the *Release* workflow by hand with a version. The tag sets the version name (`--build-name`). The build number is the workflow run number, so it always goes up.
- **Android job (Ubuntu):** `flutter build apk --release --split-per-abi`, giving `MediaDownloader-<ver>-android-{arm64-v8a,armeabi-v7a,x86_64}.apk`. Releases are signed with the release keystore, which is decoded from the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_ALIAS` into `android/key.properties`. R8 minify is off (youtubedl-android isn't R8-proofed).
- **macOS job:** `fetch_engine_binaries.sh --universal --with-deno`, then `flutter build macos --release`, then `MediaDownloader-<ver>-macos.dmg` with an Applications link. The DMG is **ad-hoc signed and not notarized**, so users allow it once under System Settings → Privacy & Security → *Open Anyway*. The release notes explain this.
- **iOS:** no release build (installs need the App Store, TestFlight or a developer's Mac).
- **Local release builds:** `android/key.properties` (gitignored) points to the keystore outside the repo. Without it, `flutter build apk --release` falls back to debug keys. **Back up the keystore and its password:** losing it means users can't update without uninstalling first.
- **App ID:** `com.gss.mediadownloader` on all platforms. Never change it after a release, or updates break.

## Scaffolding (later)

Mason bricks (`riverpod_feature`, `riverpod_view`, `domain_data_model`) could scaffold features, views and models now that the base classes (`BaseNotifier`, `BaseState`) exist. Until then, create files by hand following the [feature layout](architecture.md#project-structure).

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

- Package imports only (`package:media_tool/...`), never relative.
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
dart run pigeon --input lib/config/pigeon/system_monitor_api.dart   # System tab (Android, iOS, macOS; Windows and Linux read it in Dart)
```

Run `build_runner` after adding or changing any route, injectable class or drift table. Generated Dart clients land in `lib/core/clients/platform/`. `system_monitor_api.dart` writes the same Swift file to both `ios/Runner/SystemMonitor/` and `macos/Runner/SystemMonitor/`; the hand-written `SystemMonitor.swift` next to it is kept in sync by hand.

## App Icon and Splash

Sources live in `assets/icon/`; the `flutter_launcher_icons` and `flutter_native_splash` configs are in `pubspec.yaml` (both are dev dependencies). See [Design System](../design/design_system.md#app-icon-and-splash).

```bash
dart run flutter_launcher_icons          # Android (adaptive + monochrome), iOS, macOS, Windows (app_icon.ico) icons
dart run flutter_native_splash:create    # native splash (Android incl. 12+, iOS); not generated yet
```

Run the first after changing any icon image, the second after changing the splash images or colours. Both overwrite generated platform files (mipmaps / drawables, `AppIcon.appiconset`, launch screens), so commit their output.

## Running

After cloning, fetch the native engine files once (they're not committed):

```bash
flutter pub get
macos/scripts/fetch_engine_binaries.sh   # macOS: yt-dlp_macos, ffmpeg, ffprobe into macos/Runner/Resources/bin/ (--with-deno, --universal)
ios/scripts/fetch_engine.sh              # iOS: Python.xcframework, FFmpegKit, yt-dlp + certifi into ios/Frameworks/
linux/scripts/fetch_engine_binaries.sh   # Linux: yt-dlp_linux, ffmpeg, ffprobe into linux/engine/bin/ (--with-deno)
flutter run -d android                   # or: -d ios, -d macos, -d windows, -d linux
```

On Windows (PowerShell): `powershell -ExecutionPolicy Bypass -File windows\scripts\fetch_engine.ps1 [-WithDeno]` (yt-dlp.exe, ffmpeg.exe, ffprobe.exe into `windows\engine\bin\`). Turn on **Developer Mode** (Settings → System → For developers) before building: `pdfrx`'s build uses symlinks. Flutter only builds Windows apps on Windows and Linux apps on Linux, so the Mac can't build either; CI does.

Android needs no fetch step: youtubedl-android comes from Gradle. Xcode build phases copy the fetched files into the app (`macos/scripts/bundle_engine_binaries.sh`, `ios/scripts/install_engine.sh`); on Windows and Linux an `install()` rule in the runner's `CMakeLists.txt` copies `engine/bin/` next to the executable. Details: [Desktop Engine](../engine/desktop_engine.md), [macOS Engine](../engine/macos_engine.md), [iOS Engine](../engine/ios_engine.md).

VS Code: `.vscode/launch.json` has **Debug**, **Profile** and **Release** configurations; pick the device in the status bar.

## Releases

`.github/workflows/release.yml` builds and publishes a GitHub Release, which non-developers download from the repo's **Releases** page.

- **How to release:** ask Claude to "release" (the `release` skill in `.claude/skills/release/`). It syncs `FLUTTER_VERSION`, `JAVA_VERSION` and the action versions in the workflow with the local toolchain, validates the build, bumps `pubspec.yaml`, writes the approved notes to `.github/RELEASE_NOTES.md`, then tags and watches CI. The release body is made from `RELEASE_NOTES.md`, `.github/RELEASE_INSTALL.md` and GitHub's auto-generated changelog.
- **Trigger:** push a tag (`git tag v1.2.0 && git push origin v1.2.0`), or run the *Release* workflow by hand with a version. The tag sets the version name (`--build-name`). The build number is the workflow run number, so it always goes up.
- **Android job (Ubuntu):** `flutter build apk --release`, giving one universal `MediaTool-<ver>-android.apk` (all ABIs, so users never pick a file; it's larger than a per-ABI split). Releases are signed with the release keystore, which is decoded from the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_ALIAS` into `android/key.properties`. R8 minify is off (youtubedl-android isn't R8-proofed).
- **macOS job:** `fetch_engine_binaries.sh --universal --with-deno`, then `flutter build macos --release`, then `MediaTool-<ver>-macos.dmg` with an Applications link. The DMG is **ad-hoc signed and not notarized**, so users allow it once under System Settings → Privacy & Security → *Open Anyway*. The release notes explain this.
- **Windows job (`windows-latest`):** `fetch_engine.ps1 -WithDeno`, `flutter build windows --release`, then the `Release` folder zipped as `Media Tool\` into `MediaTool-<ver>-windows-x64.zip`. Not code-signed, so SmartScreen may ask once (*More info → Run anyway*).
- **Linux job (Ubuntu):** the GTK build packages from apt, `fetch_engine_binaries.sh --with-deno`, `flutter build linux --release`, then the bundle as `MediaTool/` in `MediaTool-<ver>-linux-x64.tar.gz` (tar keeps the executable bits). x64 only.
- **Windows and Linux are validated only by CI:** neither can be built on the Mac, so the release skill's local checks cover Android and macOS, and the tag's CI run is the first Windows / Linux build.
- **iOS:** no release build (installs need the App Store, TestFlight or a developer's Mac). Users install from source with their own Apple ID: see [Install on an iPhone](../../README.md#install-on-an-iphone) (free account: 7-day installs, renewed by reinstalling over the app, which keeps its data).
- **Local release builds:** `android/key.properties` (gitignored) points to the keystore outside the repo. Without it, `flutter build apk --release` falls back to debug keys. **Back up the keystore and its password:** losing it means users can't update without uninstalling first.
- **App ID:** `com.gss.mediatool` on all platforms. Never change it after a release, or updates break.

## Scaffolding (later)

Mason bricks (`riverpod_feature`, `riverpod_view`, `domain_data_model`) could scaffold features, views and models now that the base classes (`BaseNotifier`, `BaseState`) exist. Until then, create files by hand following the [feature layout](architecture.md#project-structure).

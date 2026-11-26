# Development

SDK, code style, lints and code generation.

## SDK

- Installed here (2026-11-25): **Flutter 3.50.1**, **Dart 3.14**. `pubspec.yaml` requires `sdk: ^3.14.0`.
- Write code for the installed SDK using its newest idioms. If a newer SDK is installed later, say so and offer to upgrade before writing feature code (the `flutter-modernize` skill does this).

## Modern Dart & Flutter

Same idioms as vAIolin:

- **Primary constructors:** `class const JobCard({super.key, required final DownloadJob job}) extends StatelessWidget { ... }`.
- **Empty bodies** end with `;`: `class MockMediaEngine extends Mock implements MediaEngine;`.
- **Dot shorthands:** `mainAxisAlignment: .center`, `padding: const .all(16)`, `borderRadius: .circular(16)`.
- **Null-aware elements** `[?maybeItem]`, wildcard `_` for unused parameters.
- **Patterns:** switch expressions, `if (x case final T y)`, `sealed` hierarchies with exhaustive `switch` (e.g. `JobStage`, `DataState`), records for small multi-value returns.
- **Material/Cupertino** come from `package:material_ui` / `package:cupertino_ui`, never `package:flutter/material.dart`.
- No deprecated APIs (`withValues(alpha:)`, not `withOpacity`).
- Never hand-edit generated files (`*.g.dart`, `*.gr.dart`, `*.config.dart`, Pigeon output). Pigeon inputs in `lib/config/pigeon/` keep classic field + constructor syntax, because Pigeon's parser needs it.

## Code Style

- Package imports only (`package:media_downloader/...`), never relative.
- Single quotes; `const` wherever possible; `if`/`for`/`while` bodies on a new line; constructors first in a class; method tear-offs over lambdas.
- `Future<void>` for async methods, never `void`.
- Short comments that explain a non-obvious *why* only.
- One widget per file; extract widgets, never `_buildX()` methods.

## Lints

`leancode_lint` (replaces the current `flutter_lints`), configured in `analysis_options.yaml`. `flutter analyze` must be clean before a task is done.

## Code Generation

```bash
# Routes (auto_route), DI (injectable), database (drift)
dart run build_runner build

# Pigeon: engine + file export bridges (Android Kotlin, iOS/macOS Swift)
dart run pigeon --input lib/config/pigeon/media_engine_api.dart
dart run pigeon --input lib/config/pigeon/file_export_api.dart
```

Run `build_runner` after adding or changing any route, injectable class or drift table.

## Running

```bash
flutter pub get
flutter run -d android     # or: -d ios, -d macos
```

macOS needs the bundled binaries first (see [macOS Engine](../engine/macos_engine.md#binaries)). iOS needs the Python and ffmpeg XCFrameworks (see [iOS Engine](../engine/ios_engine.md)).

## Scaffolding (later)

vAIolin scaffolds features, views and models with Mason bricks (`riverpod_feature`, `riverpod_view`, `domain_data_model`). The same bricks can be copied here once the base classes (`BaseNotifier`, `BaseState`) exist. Until then, create files by hand following the [feature layout](architecture.md#project-structure).

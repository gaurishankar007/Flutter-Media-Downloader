# Architecture

> Status: decided 2026-11-25, not built yet. Follows the same architecture as the vAIolin app.

Media Downloader uses **MVVM** (Model-View-ViewModel), following Flutter's official app architecture guidelines. It is **feature-first**, uses **Riverpod** for state management and **get_it + injectable** for dependency injection, and keeps business logic out of widgets.

- **UI layer:** Views (screens, widgets) and ViewModels (Riverpod `Notifier`s), grouped by feature.
- **Logic layer (optional):** use cases, for flows that combine several repositories.
- **Data layer:** repositories and services, grouped by type.

There is **no backend**. "Remote" here means the social sites themselves (fetched by the photo extractors), and the heavy work happens in the on-device **media engine** (yt-dlp + ffmpeg), which is a platform service.

## Table of Contents

- [Project Structure](#project-structure)
- [Layers](#layers)
- [State Management with Riverpod](#state-management-with-riverpod)
- [Dependency Injection](#dependency-injection)
- [Data States](#data-states)
- [Data Flow](#data-flow)
- [Media Engine](#media-engine)
- [Responsiveness](#responsiveness)
- [Docs Map](#docs-map)

## Project Structure

```text
lib/
├── config/
│   ├── injector/            # get_it + injectable setup, EngineModule (picks the engine per platform)
│   └── pigeon/              # Pigeon inputs: media_engine_api.dart, file_export_api.dart
├── core/
│   ├── clients/
│   │   ├── database/        # AppDatabase (drift)
│   │   ├── platform/        # generated Pigeon clients
│   │   └── remote/          # HttpClient (dio) with a browser User-Agent
│   ├── constants/
│   ├── data/
│   │   ├── operations/      # RepositoryFetcher helpers
│   │   └── states/          # DataState, SuccessState, FailureState, LoadingState
│   ├── errors/              # ErrorHandler, translators, recorders
│   ├── messages/            # app_messages.dart (every user-facing string)
│   ├── services/            # FileService, AppDirectories, PermissionService, ThumbnailService
│   ├── utils/               # url_utils (normalise, strip tracking params), filename_utils, extensions
│   └── app_initializer.dart
├── data/
│   ├── models/
│   │   └── responses/       # DTOs: yt-dlp JSON, extractor page JSON
│   ├── repositories/        # MediaRepositoryImpl, LibraryRepositoryImpl, ConvertRepositoryImpl, ...
│   └── services/
│       ├── local/           # LibraryLocalService, JobLocalService, SettingsLocalService, CookiesLocalService
│       ├── platform/        # MediaEngine + engine_android / engine_ios / engine_macos, FileExportService, GalleryService, ShareService, MediaPickerService
│       └── remote/          # PhotoExtractor + instagram / tiktok / facebook / threads extractors, MediaFileDownloader
├── domain/
│   ├── models/              # Site, MediaInfo, FormatOption, DownloadRequest, JobProgress, LibraryItem, ConvertRequest, AppSettings
│   ├── repositories/        # abstract contracts
│   └── use_cases/           # ResolveLinkUseCase, DownloadMediaUseCase, SaveItemUseCase
├── routing/
│   ├── routes.dart          # auto_route config
│   └── navigation_client.dart
├── ui/
│   ├── core/
│   │   ├── providers/       # BaseNotifier, BaseState, ScreenTypeNotifier
│   │   ├── themes/          # design tokens, see design_system.md
│   │   ├── ui/base/         # design-system widgets
│   │   └── utils/           # ToastUtil, UIHelpers
│   ├── features/
│   │   ├── home/            # shell: bottom nav / sidebar
│   │   ├── download/        # paste -> preview -> queue (Share / Remove on finished jobs)
│   │   ├── library/         # all items, viewer, Save to Photos / Files, Share, Delete
│   │   ├── convert/         # pick -> convert or compress -> result
│   │   └── settings/        # defaults, cookies, storage, engine update
│   ├── startup/             # StartupErrorApp, one-time rights notice
│   └── application.dart     # MediaDownloaderApp (MaterialApp.router)
└── main.dart
```

Each feature follows:

```text
lib/ui/features/<feature>/
    ├── models/       # UI-only models
    ├── providers/    # Notifiers (ViewModels)
    ├── widgets/      # widgets shared by this feature's screens
    └── views/
        └── <screen>/
            ├── <screen>_screen.dart
            └── widgets/  # widgets only this screen uses
```

There are no flavors: it's a personal app with one build. `lib/main.dart` is the only entry point.

## Layers

```mermaid
flowchart TB
    subgraph UI["UI layer (lib/ui)"]
        V["View (ConsumerWidget)"] -- "calls methods" --> N["Notifier (ViewModel)"]
        N -- "state" --> V
    end
    subgraph Logic["Logic layer (lib/domain/use_cases, optional)"]
        U["Use case"]
    end
    subgraph Data["Data layer (lib/data)"]
        R["Repository impl"]
        L["Local service (drift, files)"]
        P["Platform service (MediaEngine, gallery, export)"]
        X["Remote service (photo extractors, dio)"]
    end
    N --> U
    N --> R
    U --> R
    R --> L & P & X
```

- **Views** render state and forward user actions. They show toasts and dialogs and navigate, reacting to state through `ref.listen`.
- **Notifiers** hold screen state and call repositories or use cases. They never touch `BuildContext`, never show toasts and never navigate.
- **Use cases** combine repositories for one flow, e.g. `DownloadMediaUseCase` (engine download → post-process → thumbnail → library row).
- **Repositories** are the only thing notifiers and use cases talk to. They map DTOs to domain models and return `DataState<T>`.
- **Services** do one kind of I/O each and wrap every call in `ErrorHandler.execute`.

## State Management with Riverpod

Same rules as vAIolin:

- Every notifier extends `BaseNotifier` / `BaseAsyncNotifier` / `BaseStreamNotifier`; every state extends `BaseState` (`StateStatus` + `StateMessage`).
- `copyWith` never keeps the old `message`: it takes the argument as given, so a message can be cleared.
- A notifier runs each user flow in `runFlow('<flow label>', ...)` and reports failures with `trackFailure(dataState)` / `trackError(text)`. See [Error Handling](../core/error_handling.md).
- Text comes from `lib/core/messages/app_messages.dart`. See [App Messages](../core/app_messages.md).
- An `.autoDispose` notifier can be disposed during an `await` (e.g. the preview sheet closes mid-probe). Check `ref.mounted` before touching state after an `await`.
- A notifier that calls another notifier captures it once in `build()`, never through a lazy getter.

Long-running work (downloads, conversions) is owned by **keep-alive** notifiers (`DownloadQueueNotifier`, `ConvertJobNotifier`), so leaving a screen never cancels a job.

## Dependency Injection

- `get_it` + `injectable`; annotate with `@injectable`, `@lazySingleton` or `@singleton` and run `dart run build_runner build`.
- Platform-specific implementations use injectable **environments**, one per platform (`android`, `ios`, `macos`, in `lib/config/injector/platform_env.dart`). `configureDependencies()` passes the running platform's environment, so only that platform's classes are registered:

```dart
@LazySingleton(as: MediaEngine, env: [PlatformEnv.android])
class AndroidMediaEngine implements MediaEngine { ... }

// app_initializer.dart
await configureDependencies(environment: PlatformEnv.current); // 'android' | 'ios' | 'macos'
```

The same applies to any other service with per-platform code (e.g. `FileExportService`).

## Data States

`DataState<T>` is a sealed class: `SuccessState<T>`, `FailureState<T>`, `LoadingState<T>` (in `lib/core/data/states/`). Repositories return `Future<DataState<T>>` or `Stream<DataState<T>>`. Methods with no result use `FutureVoid` and return `const SuccessState.nil()` on success.

Progress streams (`Stream<DataState<JobProgress>>`) emit `SuccessState` for each progress update and end with one `SuccessState` (completed) or one `FailureState`.

## Data Flow

Download, from paste to library:

```mermaid
flowchart TD
    A["LinkField: Paste"] --> B["MediaPreviewNotifier.probe(url)"]
    B --> C["ResolveLinkUseCase"]
    C -- "normalise URL, follow short links, detect Site" --> D{"Photo post?"}
    D -- "yes (known photo URL, or engine says 'no video')" --> E["PhotoExtractor (Dart)"]
    D -- "no" --> F["MediaEngine.probe (yt-dlp -J)"]
    E & F --> G["MediaInfo -> preview sheet"]
    G -- "Download" --> H["DownloadQueueNotifier.enqueue"]
    H --> I["DownloadMediaUseCase"]
    I --> J["MediaEngine.download / MediaFileDownloader"]
    J --> K["post-process (ffmpeg: iPhone re-encode, JPG)"]
    K --> L["ThumbnailService"]
    L --> M["LibraryRepository.add (drift row, file in app folder)"]
    M --> N["JobCard: Done + Share / Remove"]
```

Details: [Download](../features/download.md), [Library](../features/library.md), [Convert](../features/convert.md).

## Media Engine

`MediaEngine` is the single Dart interface over yt-dlp and ffmpeg. Each platform has its own implementation in `lib/data/services/platform/media_engine/`:

| Platform | Implementation | How it talks |
| --- | --- | --- |
| Android | `AndroidMediaEngine` | Pigeon `@HostApi` + `@EventChannelApi` → Kotlin (youtubedl-android) |
| iOS | `IosMediaEngine` | Pigeon → Swift → embedded CPython running `yt_dlp` as a module; ffmpeg linked as a library |
| macOS | `MacosMediaEngine` | `dart:io` `Process` running bundled `yt-dlp_macos`, `ffmpeg`, `ffprobe` |

See [Media Engine](../engine/media_engine.md).

## Responsiveness

`ScreenTypeNotifier` tracks the breakpoint (phone / tablet / desktop). The root widget listens for `didChangeMetrics` and updates it in a post-frame callback, the same pattern as vAIolin's `ScreenObserverNotifier`. Layout rules are in the [Design System](../design/design_system.md#layout-and-navigation).

## Docs Map

| Area | Doc |
| --- | --- |
| Startup | [App Startup](app_startup.md) |
| SDK, lints, codegen | [Development](development.md) |
| Look and feel | [Design System](../design/design_system.md) |
| Routing | [Routing](../core/routing.md) |
| Errors | [Error Handling](../core/error_handling.md) |
| Strings | [App Messages](../core/app_messages.md) |
| Database | [Local Database](../core/local_database.md) |
| Files, permissions, thumbnails | [Core Services](../core/core_services.md) |
| Engine | [Media Engine](../engine/media_engine.md), [Android](../engine/android_engine.md), [iOS](../engine/ios_engine.md), [macOS](../engine/macos_engine.md), [ffmpeg Recipes](../engine/ffmpeg_recipes.md), [Site Support](../engine/site_support.md) |
| Photo posts | [Photo Extractors](../extractors/photo_extractors.md) |
| Features | [Download](../features/download.md), [Library](../features/library.md), [Convert](../features/convert.md), [Settings](../features/settings.md) |
| Packages, problems | [Packages](../utils/packages.md), [Troubleshooting](../utils/troubleshooting.md) |

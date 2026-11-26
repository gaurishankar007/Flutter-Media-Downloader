# Core Services

> Status: built. Files: `lib/core/services/`, `lib/core/utils/`, `lib/data/services/platform/`.

Shared services that more than one feature uses.

## App Directories

`AppDirectories` (`lib/core/services/app_directories.dart`, `@singleton`) resolves every folder once at startup (`init()`, safe to call again on startup Retry):

| Folder | Where | Holds |
| --- | --- | --- |
| `base` | Application Support (`path_provider`): iOS/macOS Application Support, Android `filesDir`-based app support dir | Root for everything below |
| `downloads/` | under base | Finished downloads and conversions (the Library) |
| `thumbnails/` | under base | JPG thumbnails for Library items, named `<item id>.jpg` |
| `cookies/` | under base | Imported cookies.txt per site (mode 600 on macOS) |
| `engine/` | under base (macOS only) | Self-updated copy of `yt-dlp_macos` (see [macOS Engine](../engine/macos_engine.md)) |
| `work/` | Application cache dir | One `work/<jobId>/` per job: partial downloads, ffmpeg intermediates. **Deleted on every startup.** |

- On iOS, `BackupExclusion` (`ios/Runner/Storage/BackupExclusion.swift`, run from `AppDelegate` at launch) marks `downloads/`, `thumbnails/`, `cookies/` and `engine/` "exclude from backup", so large files and cookies never go to iCloud.
- Paths in the database are relative to `base`: `resolve(relative)` / `relative(absolute)` convert (see [Local Database](local_database.md#paths-are-stored-relative)).

## FileService

`FileService` (`lib/core/services/file_service.dart`) wraps file operations so nothing above the data layer uses `dart:io`: `move` (rename, or copy + delete across file systems), `copy`, `createDir`, `delete` (file or folder), `sizeOf`, `listFiles(dir)`, `uniqueName(dir, name)` (adds ` (2)`, ` (3)`… before the extension on clashes). Methods throw; repositories call them inside `ErrorHandler.execute`.

`ClipboardService` (`lib/core/services/clipboard_service.dart`) reads and writes plain text (Paste on Download, Copy of the error log).

## Filenames

`FilenameUtils` (`lib/core/utils/filename_utils.dart`):

- `fromTitle(title, extension:, suffix:)`: drops trailing `#hashtags` / @mentions, keeps Unicode (Hindi, emoji, etc.), only replaces characters illegal on the filesystem (`/ \ : * ? " < > |` and control characters), trims to about 80 characters on a word boundary, and adds the quality: `Title [1080p].mp4`, `Title.mp3`.
- `forPostItem(uploader:, postId:, index:, fallback:)`: photo post items, `<user> <postid> 01.jpg`, `02.jpg`, … (no number for a single item; falls back to the title without a user or id).

Other helpers in `lib/core/utils/`: `FormatUtils` (bytes, speed, duration, ETA via `intl`), `MimeUtils.forPath` (MIME type by extension, for Save to Files).

## URL Utils

`UrlUtils` (`lib/core/utils/url_utils.dart`):

- `extractUrl(text)`: the first URL in pasted text ("Check this out https://…"), trailing punctuation dropped, https added if missing.
- `normalise(url)`: force https, strip tracking params (`igsh`, `igshid`, `fqnt`, `si`, `fbclid`, `is_from_webapp`, `sender_device`, `feature`, `ref`, `s`, `mibextid`, `utm_*`).
- `isShortLink(url)`: `vm.tiktok.com`, `vt.tiktok.com`, `fb.watch`, `t.co`, `instagr.am`, Facebook `/share/…`. These are followed before routing (see [Photo Extractors](../extractors/photo_extractors.md#routing-a-link)).
- `detectSite(url)` → `Site?` by registrable domain (subdomains match): youtube (`youtube.com`, `youtu.be`), facebook (`facebook.com`, `fb.watch`, `fb.com`), instagram (`instagram.com`, `instagr.am`), tiktok (`tiktok.com`), x (`x.com`, `twitter.com`, `t.co`), threads (`threads.net`, `threads.com`); `null` for anything else.
- `looksLikePhotoPost(url)`: TikTok `/photo/`; Facebook `/photo…`, `/photos/`, `photo.php`. Instagram `/p/` can be either, so it's decided by trying.

## Platform Services

All in `lib/data/services/platform/`, each behind an interface. Per-platform implementations use injectable environments.

| Service | Does | Built on |
| --- | --- | --- |
| `MediaEngine` | probe, download, ffmpeg, cancel, update | See [Media Engine](../engine/media_engine.md) |
| `GalleryService` | Save a video or photo to Photos (iOS/macOS) / the gallery (Android), into a `MediaTool` album. **Audio can't** go to Photos (`supports(kind)` is false), so the Library hides that action for audio. | `gal` |
| `FileExportService` | Save to Files. Returns `true` when saved, `false` when cancelled. Android: SAF `ACTION_CREATE_DOCUMENT` + streamed copy (Kotlin `export/FileExporter.kt`). iOS: `UIDocumentPickerViewController(forExporting:)` (Swift `Runner/Export/FileExporter.swift`). Both through Pigeon `file_export_api.dart`. macOS: `NSSavePanel` via `file_picker`'s `saveFile`, then a Dart file copy. | Pigeon / `file_picker` |
| `ShareService` | System share sheet for one or more files | `share_plus` |
| `MediaPickerService` | Converter import: `pickFromPhotos()` (media picker), `pickFromFiles()` (any file), `clearTemporaryFiles()` | `file_picker` |
| `FilePickerService` | One file read once (cookies.txt import) | `file_picker` |
| `ImageService` | `toJpg` (full size, quality 92) and `thumbnail` (short side ~480 px) | `flutter_image_compress` |
| `ImageConvertService` | Converter images: output formats this platform can write, decoded size, convert/resize/strip metadata | `flutter_image_compress`, `dart:ui` |
| `AppInfoService` | App version `1.0.0 (1)` for About | `package_info_plus` |
| `BackgroundWorkService` | Android: the `dataSync` foreground service + notification with Cancel (Pigeon `background_work_api.dart`). iOS/macOS: no-op. | Pigeon / `permission_handler` |
| `SystemMonitorService` | RAM / CPU / GPU / network samples for the System tab | Pigeon `system_monitor_api.dart`, see [System](../features/system.md) |

Save to Photos and Save to Files return a **confirmed result** (saved / cancelled / failed), which is what lets the Library show the "remove from app?" prompt safely. The share sheet doesn't give a reliable result on every platform, so no prompt follows Share.

## Permissions

Asked only at the moment they're needed; there's no separate permission service.

| When | iOS | Android | macOS |
| --- | --- | --- | --- |
| Save to Photos | Photos (`NSPhotoLibraryAddUsageDescription` / `NSPhotoLibraryUsageDescription`), requested by `GalleryService` through `gal` | None on Android 10+; `WRITE_EXTERNAL_STORAGE` (maxSdk 29) on 9 and lower | Same as iOS |
| Import from Photos / Files | None (system picker) | None (system picker) | None |
| Download notifications | — | `POST_NOTIFICATIONS` (Android 13+), requested by `AndroidBackgroundWorkService` via `permission_handler` when a download starts | — |

A denied Photos permission comes back as a `GalException` and is shown with `LibraryMessages.photosAccessDenied` (see [Error Handling](error_handling.md#translators)).

## Thumbnails

There's no separate thumbnail service. Every Library item gets a JPG in `thumbnails/` when one can be made:

- Engine downloads: yt-dlp writes the site's thumbnail (`--write-thumbnail --convert-thumbnails jpg`) into the job's work folder; `LibraryRepository.addDownload` moves it.
- Photo posts: each photo is downscaled with `ImageService.thumbnail`; post videos use the still the extractor found.
- TikTok "Save as video": the first photo.
- Converted videos: one frame at 10% of the duration (`FfmpegCommandBuilder.thumbnail`), through the engine. Converted images: `ImageService.thumbnail`.
- Audio without a thumbnail: none (the card shows a music icon on a gradient).

Generation is best-effort (`executeSafeReturn`): a missing thumbnail never fails a download.

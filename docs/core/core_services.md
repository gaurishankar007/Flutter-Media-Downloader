# Core Services

> Status: planned. Files: `lib/core/services/`, `lib/core/utils/`, `lib/data/services/platform/`.

Shared services that more than one feature uses.

## App Directories

`AppDirectories` (`lib/core/services/app_directories.dart`) resolves every folder once at startup:

| Folder | iOS | Android | macOS | Holds |
| --- | --- | --- | --- | --- |
| `base` | Application Support | `filesDir` | `~/Library/Application Support/<bundle id>` | Root for everything below |
| `downloads/` | under base | under base | under base | Finished downloads and conversions (the Library) |
| `thumbnails/` | under base | under base | under base | JPG thumbnails for Library items |
| `work/` | Caches | `cacheDir` | Caches | Partial downloads, ffmpeg intermediates; cleared on startup |
| `cookies/` | under base, excluded from backup | under base | under base, mode 600 | Imported cookies.txt per site |
| `engine/` | — | — | under base | Self-updated `yt-dlp_macos` |

- On iOS, `downloads/` and `cookies/` are marked "exclude from backup" so large files and cookies don't go to iCloud.
- Paths in the database are relative to `base` (see [Local Database](local_database.md#paths-are-stored-relative)).

## FileService

Wraps file operations so notifiers and repositories never use `dart:io` directly: `move`, `copy`, `delete`, `exists`, `sizeOf`, `freeSpace` (used before a big download to warn early), `uniqueName(dir, name)` (adds ` (2)`, ` (3)`… on clashes).

## Filenames

`FilenameUtils.fromTitle(title, {suffix})`:

- Remove `#hashtags` and @mentions at the end of titles.
- Keep Unicode (Hindi, emoji, etc.); only replace characters illegal on the filesystem (`/ \ : * ? " < > |` and control characters).
- Trim to about 80 characters on a word boundary.
- Add the quality: `Title [1080p].mp4`, `Title.mp3`; photo posts: `<user> <postid> 01.jpg`, `02.jpg`, …

## URL Utils

`UrlUtils` (`lib/core/utils/url_utils.dart`):

- `extractUrl(text)`: pull the first URL out of pasted text (people paste "Check this out https://…").
- `normalise(url)`: force https, strip tracking params (`igsh`, `fqnt`, `si`, `utm_*`, `fbclid`, `t` on X share links, `is_from_webapp` etc.).
- `detectSite(url)` → `Site` enum: youtube (`youtube.com`, `youtu.be`, `music.youtube.com`), facebook (`facebook.com`, `fb.watch`, `m.facebook.com`), instagram, threads (`threads.net`, `threads.com`), x (`x.com`, `twitter.com`), tiktok (`tiktok.com`, `vm.tiktok.com`, `vt.tiktok.com`), unknown.
- `looksLikePhotoPost(url)`: TikTok `/photo/`, Facebook `/photo`, `/photos/`, `photo.php`. Instagram `/p/` can be either, so it's decided by trying.

## Platform Services

All in `lib/data/services/platform/`, each behind an interface with one implementation per platform when needed:

| Service | Does | Built on |
| --- | --- | --- |
| `MediaEngine` | probe, download, convert, cancel, update | See [Media Engine](../engine/media_engine.md) |
| `GalleryService` | Save a file to Photos (iOS/macOS) / gallery (Android, into `Movies/MediaDownloader`, `Pictures/MediaDownloader`, `Music/MediaDownloader`) | `gal` package |
| `FileExportService` | Save to Files: iOS `UIDocumentPickerViewController(forExporting:)`, Android SAF `ACTION_CREATE_DOCUMENT` with a streamed copy, macOS `NSSavePanel` | Pigeon `file_export_api.dart` (streams the file, never loads it into memory) |
| `ShareService` | System share sheet | `share_plus` |
| `MediaPickerService` | Import from Photos / gallery, and from Files | `image_picker` (`pickMultipleMedia`), `file_picker` |

Save to Photos and Save to Files return a **confirmed result** (saved / cancelled / failed), which is what lets the Library show the "remove from app?" prompt safely. The share sheet doesn't give a reliable result on every platform, so no prompt follows Share.

## Permissions

`PermissionService` wraps `permission_handler` and only asks at the moment it's needed:

| When | iOS | Android | macOS |
| --- | --- | --- | --- |
| Save to Photos | Photos **add-only** (`NSPhotoLibraryAddUsageDescription`) | None on Android 10+ (MediaStore); `WRITE_EXTERNAL_STORAGE` on 9 and lower | Photos add-only |
| Import from Photos | None (system picker) | None (photo picker) | None |
| Download notifications | — | `POST_NOTIFICATIONS` (Android 13+) | — |

If a permission was denied for good, show a dialog with **Open Settings** instead of failing silently.

## Thumbnails

`ThumbnailService` makes a 480px-wide JPG for every Library item:

- Video: one frame at 10% of the duration (ffmpeg `-ss` + `-frames:v 1`), through the engine.
- Photo: downscaled copy (`flutter_image_compress`).
- Audio: the embedded cover art if any, otherwise the site's thumbnail downloaded at probe time, otherwise none (the card shows a music icon on a gradient).

Generation is best-effort (`executeSafe`): a missing thumbnail never fails a download.

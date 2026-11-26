# App Messages

> Status: built. File: `lib/core/messages/app_messages.dart`. Current `kMessagesVersion`: `7`.

Every string the app writes itself (toasts, dialog text, empty and error states, button labels, semantic labels, validator errors) lives in one catalog. Never write a user-facing literal at the call site.

## Layout

One class per area, sub-sections inside, a `///` comment on each saying when it's shown:

```dart
abstract final class DownloadMessages {
  /// LinkField: clipboard has no URL.
  static const clipboardEmpty = 'Copy a link first, then tap Paste.';

  /// Hint under LinkField: URL isn't from a supported site.
  static const unsupportedLink = "This link isn't from a supported site.";
}
```

Areas, in file order:

| Class | Holds |
| --- | --- |
| `CommonMessages` | Generic error, storage errors, shared buttons (Retry, OK, Cancel, Close, Back, Share, Delete…) |
| `JobStageMessages` | Stage labels on job cards (downloading, processing, saving…) |
| `SavedPromptMessages` | The "remove from app?" prompt after a confirmed save |
| `NavMessages` | Tab labels: Download, Library, Convert, System, Settings |
| `StartupMessages` | Startup error screen and the one-time rights notice |
| `DownloadMessages` | Download screen, preview sheet, job cards, photo posts |
| `EngineMessages` | Engine failure texts (see [Error Handling](error_handling.md#engine-error-mapping)) |
| `ExtractorMessages` | Photo extractor failures (see [Photo Extractors](../extractors/photo_extractors.md)) |
| `LibraryMessages` | Library grid, filters, viewer, item actions |
| `ConvertMessages` | Converter and compressor |
| `SettingsMessages` | Settings screen |
| `CookiesMessages` | Cookies screen |
| `AboutMessages` | About screen |
| `SystemMessages` | System tab (metric names, storage and battery rows, idle speed, unavailable state) |
| `DesignGalleryMessages` | Debug-only design gallery, incl. the toast demo strings |

## Writing Style

- Short, plain, second person: "Copy a link first, then tap Paste."
- Say what to do next when something fails ("Import cookies in Settings.").
- No technical words (no "yt-dlp", "ffmpeg", "HTTP 429") in user text. The error log keeps the technical detail.

## Versioning

`kMessagesVersion` sits at the top of the file, under a library doc comment that is the changelog. When a message's wording changes, or a message is added or removed, bump it and add one line there:

| Version | Change |
| --- | --- |
| 2 | Removed `DownloadMessages.engineComing` (the engine exists). |
| 3 | `EngineMessages.needsLogin` / `botCheck` point to cookies; Settings engine and cookies tiles reworded; `defaultQuality` → `defaultVideoQuality`. |
| 4 | `EngineMessages.noVideo` no longer says photos are coming; added photo post strings (`DownloadMessages` photos…, `ExtractorMessages`). |
| 5 | Removed `EngineMessages.notOnThisPlatform` (every platform has an engine), the duplicates `DownloadMessages.retry` (use `CommonMessages.retry`) and `ExtractorMessages.network` (use `EngineMessages.network`), and `CommonMessages.comingSoon` (every feature is built). |
| 6 | Added `NavMessages.system` (System is a tab); removed `SystemMessages.openSystem`. |
| 7 | Added `DesignGalleryMessages` toast demo strings, `ConvertMessages.savePhotosShort` / `saveFilesShort`, `LibraryMessages.loadFailed`, `SystemMessages.unavailableTitle` / `unavailableBody`. |
| 8 | Added `SystemMessages` storage and battery strings. |
| 9 | Added `SystemMessages.batteryCycles` and `batteryHealthWithPercent`. |

## Localisation

English only. The catalog keeps all text in one place so moving to ARB files later is mechanical. (`intl` is used only for number and date formatting.)

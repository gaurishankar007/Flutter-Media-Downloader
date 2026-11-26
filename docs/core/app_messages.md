# App Messages

> Status: planned. File: `lib/core/messages/app_messages.dart`.

Every string the app writes itself (toasts, dialog text, empty and error states, button labels, semantic labels, validator errors) lives in one catalog. Never write a user-facing literal at the call site.

## Layout

One class per area, sub-sections inside, a `///` comment on each saying when it's shown:

```dart
abstract final class DownloadMessages {
  /// LinkField: clipboard has no URL.
  static const clipboardEmpty = 'Copy a link first, then tap Paste.';

  /// LinkField: URL isn't from a supported site.
  static const unsupportedLink = "This link isn't from a supported site.";

  /// JobCard: Remove confirm dialog.
  static const removeTitle = 'Remove from app?';
  static const removeBody = 'The file will be deleted from the app. Copies you saved to Photos or Files stay.';
}
```

Areas: `CommonMessages`, `DownloadMessages`, `LibraryMessages`, `ConvertMessages`, `SettingsMessages`, `EngineMessages` (the failure texts in [Error Handling](error_handling.md#engine-error-mapping)), `PermissionMessages`.

## Writing Style

- Short, plain, second person: "Copy a link first, then tap Paste."
- Say what to do next when something fails ("Import cookies in Settings.").
- No technical words (no "yt-dlp", "ffmpeg", "HTTP 429") in user text. The error log keeps the technical detail.

## Versioning

`kMessagesVersion` at the top of the file. When a message's wording changes or a message is removed, bump it and add one changelog line to its doc comment.

## Localisation

English only in v1. The catalog keeps all text in one place so moving to `intl` / ARB files later is mechanical.

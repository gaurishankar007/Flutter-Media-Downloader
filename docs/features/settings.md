# Settings

> Status: planned (v1 step 6; Storage and Engine basics come earlier, when the features that need them land). Feature folder: `lib/ui/features/settings/`.

## Sections

| Section | Setting | Default |
| --- | --- | --- |
| **Downloads** | Default video quality (Best / 4K / 1440p / 1080p / 720p / 480p) | 1080p |
| | Default audio quality (320 / 192 / 128 kbps) | 320 |
| | iPhone-compatible video | On |
| | Photos: convert to JPG (off = keep original WebP/HEIC) | On |
| **Library & storage** | Ask to remove from the app after saving | On |
| | Storage used (Videos / Audio / Photos breakdown) | — |
| | Clear items already saved to Photos or Files | — |
| **Cookies** | Per site: import cookies.txt, status, remove; macOS: use browser cookies | None |
| **Engine** | yt-dlp version, **Update**, check for updates on launch | On (at most daily) |
| **Appearance** | Theme: System / Dark / Light | System |
| **About** | Rights notice, app version, engine versions, open-source licences, error log (copy) | — |

Settings are one `AppSettings` model stored as JSON in `KeyValueLocal` (see [Local Database](../core/local_database.md)). `SettingsRepository.watch()` is a stream, so changes apply everywhere immediately.

## Providers

| Provider | Owns | Key methods |
| --- | --- | --- |
| `settingsProvider` (`SettingsNotifier`, keep-alive) | `AppSettings` | `update(AppSettings Function(AppSettings))` |
| `engineStatusProvider` (`EngineStatusNotifier`, keep-alive) | init status, versions, update check result | `init()`, `checkForUpdate()`, `update()` |
| `cookiesProvider` (`CookiesNotifier`) | Per-site cookie status | `import(site)`, `remove(site)`, `setBrowser(browser)` |
| `storageProvider` (`StorageNotifier`, `.autoDispose`) | Sizes by kind | `refresh()`, `clearSaved()` |

## Cookies

- **Import:** pick a Netscape cookies.txt (`file_picker`). The file is validated (Netscape header, at least one cookie for that site's domain), then **copied** into `cookies/<site>.txt` in the app's private folder. Only cookies for that site's domains are kept; the rest are dropped.
- **Use:** yt-dlp gets `--cookies cookies/<site>.txt`; Dart extractors send them only to that site's domain.
- **macOS:** optional "Use cookies from Safari / Chrome / Firefox" → `--cookies-from-browser`.
- **Never** uploaded, logged, included in the error log or backups. **Remove** deletes the file.
- The Cookies screen explains how to export cookies.txt with a browser extension, in plain steps.

## Engine

- Shows the yt-dlp version (and ffmpeg version) from `EngineInfo`.
- **Update** calls `MediaEngine.updateYtDlp()` and shows the new version, or "Already up to date".
- "Check on launch": at most once a day, after the first frame. If an update exists, a dot appears on the Settings tab and a banner on Settings → Engine. It doesn't update by itself.
- When a download fails with `ExtractorBrokenFailure`, its job card offers **Update engine** directly.

# Settings

> Status: built (v1 step 6), not yet tested on every device. Feature folder: `lib/ui/features/settings/`.

## Screens

| Screen | Route | What |
| --- | --- | --- |
| `SettingsScreen` | Settings tab (`settings`) | All sections below |
| `CookiesScreen` | `CookiesRoute` (`/settings/cookies`), full screen above the tabs | Per-site cookies, desktop browser cookies, how-to |
| `AboutScreen` | `AboutRoute` (`/settings/about`), full screen above the tabs | Versions, rights notice, licences, error log |
| `DesignGalleryScreen` | `DesignGalleryRoute` (`/design-gallery`) | Debug builds only (Developer section): every base widget, see [Design System](../design/design_system.md) |

Sub-pages use `ScreenBackButton` + `ScreenHeader` inside a `ScreenScrollView`.

## Sections

| Section | Setting | Default |
| --- | --- | --- |
| **Downloads** | Default video quality (Best / 4K / 1440p / 1080p / 720p / 480p) | 1080p |
| | Default audio quality (320 / 192 / 128 kbps) | 320 |
| | iPhone-compatible video | On |
| | Convert photos to JPG (off = keep the original WebP / HEIC) | On |
| **Library & storage** | Ask to remove from the app after saving (`askRemoveAfterSave`) | On |
| | Storage used (Videos / Audio / Photos / PDFs breakdown) | — |
| | Clear items already saved to Photos or Files (with a confirm) | — |
| **Cookies** | Tile with how many sites have cookies → `CookiesRoute` | None |
| **Engine** | yt-dlp version + **Update**, update banner, check for updates on launch | On (at most daily) |
| **Appearance** | Theme: System / Dark / Light | System |
| **About** | Rights notice (dialog), About → `AboutRoute` | — |
| **Developer** (debug only) | Design gallery | — |

Settings are one `AppSettings` model stored as JSON under the `settings` key in `KeyValueLocal` (see [Local Database](../core/local_database.md)). Besides the rows above it holds `rightsNoticeAccepted`, `cookieBrowser` and `lastEngineCheckAt`. `SettingsRepository.watch()` is a stream, so changes apply everywhere immediately.

Settings and engine messages (toasts) are shown by the home shell, not the Settings screen, so a change made from any tab (e.g. **Update engine** on a failed job card) gets exactly one toast.

## Providers

| Provider | Owns | Key methods |
| --- | --- | --- |
| `settingsProvider` (`SettingsNotifier`, keep-alive) | `AppSettings` | `setThemeMode()`, `acceptRightsNotice()`, `setDefaultVideoQuality()`, `setDefaultAudioQuality()`, `setIphoneCompatible()`, `setPhotosToJpg()`, `setAskRemoveAfterSave()`, `setCookieBrowser()`, `setCheckEngineOnLaunch()`, `markEngineChecked()`, `update(change)` |
| `engineStatusProvider` (`EngineStatusNotifier`, keep-alive, in `download/providers/`) | Engine init status, `EngineInfo`, update status, `availableVersion` | `retry()`, `checkForUpdate({silent})`, `update()` |
| `cookiesProvider` (`CookiesNotifier`, `.autoDispose`) | Per-site `SiteCookies` (count, imported date), the busy site, `cookieBrowsers` (this platform's choices; `supportsBrowserCookies` when there are any) | `refresh()`, `import(site)`, `remove(site)`, `setBrowser(browser)` |
| `storageProvider` (`StorageNotifier`, `.autoDispose`) | `StorageUsage` (bytes by kind, saved count/bytes) | `refresh()`, `clearSaved()` |
| `aboutProvider` (`AboutNotifier`, `.autoDispose`) | App version (`package_info_plus`) | `copyErrorLog()` |

## Cookies

- **Import:** pick a file (`file_picker`). It's validated (at most 5 MB, readable text, a Netscape "HTTP Cookie File" header, at least one cookie for that site's domains), only that site's cookies are kept, and the result is written as `cookies/<site>.txt` in the app's private folder (`chmod 600` on macOS and Linux).
- **Use:** yt-dlp gets `--cookies cookies/<site>.txt`. Dart extractors get a `Cookie` header from `CookiesLocalService.cookieHeader(site, url)`, which returns nothing unless the URL is on that site's own domains (and respects secure / expiry).
- **Desktops:** "Browser cookies" (default none) → `--cookies-from-browser <name>` when a site has no cookies.txt. The choices come from `CookiesRepository.cookieBrowsers` (`CookieBrowser.availableOn`): Safari, Chrome and Firefox on macOS; Chrome and Firefox on Linux; Firefox on Windows (Chrome 127+ encrypts its cookies so only Chrome can read them). The section is hidden where the list is empty (Android, iOS). A saved choice that isn't offered on this platform is ignored.
- **Never** uploaded or logged (failures carry only a user message). **Remove** asks first, then deletes the file. On iOS the `cookies/` folder is excluded from backups.
- The Cookies screen ends with `CookiesHowToCard`: how to export cookies.txt with a browser extension, in plain steps.

## Engine

- Shows the yt-dlp version from `EngineInfo` (no ffmpeg version), or "Not available on this device yet" when the engine failed to start.
- **Check for updates:** `MediaRepository.checkForUpdate()` asks GitHub's API for the latest yt-dlp release (`api.github.com/repos/yt-dlp/yt-dlp/releases/latest`, anonymous, `EngineReleaseService`) and compares its tag with the installed version.
- **Update** calls `MediaEngine.updateYtDlp()` through `MediaRepository.updateEngine()` and toasts "Download engine updated to …" or "already up to date". See [Media Engine](../engine/media_engine.md#updates).
- "Check on launch": after the engine is ready, at most once a day (`lastEngineCheckAt`), silently. If an update exists, a dot appears on the Settings tab (`NavBadgeDot`) and `EngineUpdateBanner` on Settings → Engine. It never updates by itself.
- When a download fails because the site changed (`EngineMessages.extractorBroken`), its job card offers **Update engine** directly; a login or bot-check failure offers **Import cookies** (→ `CookiesRoute`). See [Download](download.md#job-card).

## About

`AboutScreen`: app version and yt-dlp version, rights notice, open-source licences (`showLicensePage`), and **Copy** for the error log (copies the on-device error log to the clipboard; it's never sent anywhere).

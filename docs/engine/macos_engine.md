# macOS Engine

> Status: implemented (not yet tested beyond the development Mac). Dart: `desktop_media_engine.dart` (shared with Windows and Linux, see [Desktop Engine](desktop_engine.md)). No native code for the engine itself.

## Binaries

Bundled in `Contents/Resources/bin/` (source folder `macos/Runner/Resources/bin/`, not committed; only `.gitkeep` is):

| Binary | Where it comes from |
| --- | --- |
| `yt-dlp_macos` | Official standalone universal2 build from https://github.com/yt-dlp/yt-dlp/releases (latest), checked against `SHA2-256SUMS` |
| `ffmpeg`, `ffprobe` | Static builds from ffmpeg.martin-riedl.de (VideoToolbox, libmp3lame, libx264, x265) |
| `deno` (optional) | https://github.com/denoland/deno/releases, for YouTube's JavaScript challenges |

### Fetch script

Run once after cloning, and again to refresh:

```bash
macos/scripts/fetch_engine_binaries.sh               # this Mac's arch
macos/scripts/fetch_engine_binaries.sh --universal   # arm64 + x86_64 ffmpeg (lipo)
macos/scripts/fetch_engine_binaries.sh --with-deno   # also bundle deno
```

It downloads into `macos/Runner/Resources/bin/`, makes the files executable, clears quarantine attributes and prints the versions.

### Bundle script

`macos/scripts/bundle_engine_binaries.sh` is a Run Script build phase of the Runner target. It copies every file in `Runner/Resources/bin/` into `Contents/Resources/bin/`, clears extended attributes and signs each one ad-hoc (`codesign --force --sign -`) so macOS lets them run. Unchanged binaries (same mtime) are skipped so incremental builds stay fast. If `yt-dlp_macos` or `ffmpeg` is missing it prints a build warning and the app builds anyway (the engine then fails to start with "Engine binaries missing").

## Running

- `DesktopMediaEngine` runs the binaries with `dart:io` `Process.run` (probe, `--version`, `-encoders`, `-U`) and `Process.start` (downloads, ffmpeg jobs), reading stdout line by line as UTF-8 and keeping the last 4000 characters of stderr for errors.
- **Environment:** a GUI app starts with a bare `PATH` and no locale, so every process gets `PATH = <bin>:/opt/homebrew/bin:/usr/local/bin:<inherited PATH>` (the bundled tools first, then Homebrew for a `deno` that isn't bundled) and `LANG` / `LC_ALL = en_US.UTF-8`, `PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`, so titles and file names survive.
- **Extra yt-dlp args** the shared builder can't know: `--ffmpeg-location <bin>`, and `--js-runtimes deno:<bin>/deno` when `deno` is bundled.
- yt-dlp progress comes from `--newline` + the `[MD]` progress template (see [Media Engine: Download Args](media_engine.md#download-args)); ffmpeg progress from `-progress pipe:1`.
- **Cookies:** the site's imported cookies.txt (`--cookies`), else `--cookies-from-browser safari|chrome|firefox` from Settings → Cookies (all three on macOS; Windows and Linux offer fewer, see [Site Support](site_support.md#cookies)).
- **Cancel:** `yt-dlp_macos` is a bootloader with Python (and ffmpeg) below it, so cancel sends SIGTERM to the process and all its descendants (`pgrep -P`), then SIGKILL after 3 s.

## App Sandbox: off

Running bundled binaries and reading browser cookies needs the sandbox off. `com.apple.security.app-sandbox` is `<false/>` in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` (both also have network client, user-selected read-write files and the Photos library entitlement). The app only runs from source on your own Mac, so that's fine. `Info.plist` has `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`.

## Updating yt-dlp

The app bundle is read-only after signing (changing a file inside it breaks the signature). Before first use, `yt-dlp_macos` is copied to `~/Library/Application Support/<bundle id>/engine/yt-dlp_macos` (`chmod 755`) and that copy is the one that runs; `yt-dlp -U` updates it in place. If the copy is missing or `--version` fails, it's copied again; if that still fails the engine falls back to the bundled binary (which can't be updated, so **Update** reports a failure).

## Saving

- **Save to Photos:** `gal` (Photos add-only permission).
- **Save to Files:** the `NSSavePanel` from `file_picker` (`FilePicker.saveFile`, defaulting to the item's name), then a streamed copy to the chosen path (`DesktopFileExportService`, shared with Windows and Linux). No Pigeon on the desktops.

There is no **Show in Finder** action and no drag-and-drop target yet.

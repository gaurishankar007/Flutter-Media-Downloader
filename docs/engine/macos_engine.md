# macOS Engine

> Status: planned (v1 step 4). Dart: `macos_media_engine.dart`. No native code for the engine itself.

## Binaries

Bundled in `Contents/Resources/bin/` (source folder `macos/Runner/Resources/bin/`, not committed):

| Binary | Where to get it |
| --- | --- |
| `yt-dlp_macos` | https://github.com/yt-dlp/yt-dlp/releases (standalone, universal) |
| `ffmpeg`, `ffprobe` | Static macOS builds (universal or arm64 + x86_64) with `videotoolbox` and `libmp3lame` |
| `gallery-dl` (optional) | Standalone build, or Homebrew/pip during development |

A Run Script build phase copies them into the bundle and signs each one (ad-hoc, `codesign --force --sign - "$BIN"`), so macOS lets them run. In development, clear the quarantine flag once: `xattr -d com.apple.quarantine macos/Runner/Resources/bin/*`.

## Running

- `MacosMediaEngine` runs them with `dart:io` `Process.start`, reading stdout/stderr line by line.
- yt-dlp progress comes from `--newline` + the `[MD]` progress template (see [Media Engine: Download Args](media_engine.md#download-args)); ffmpeg progress from `-progress pipe:1`.
- yt-dlp is pointed at the bundled ffmpeg with `--ffmpeg-location`.
- Cookies: either an imported cookies.txt (`--cookies`) or, macOS only, `--cookies-from-browser safari|chrome|firefox` (Settings → Cookies).

## App Sandbox: off

Running bundled binaries and reading browser cookies needs the sandbox off. Remove `com.apple.security.app-sandbox` from `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`. The app only runs from source on your own Mac, so that's fine. Photos access needs `NSPhotoLibraryAddUsageDescription` in `Info.plist`.

## Updating yt-dlp

The app bundle is read-only after signing (changing a file inside it breaks the signature). On first launch, `yt-dlp_macos` is copied to `~/Library/Application Support/<bundle id>/engine/` and that copy is the one that runs; `yt-dlp -U` updates it in place. If the copy is missing or broken, the engine falls back to the bundled one.

## Saving

- **Save to Photos:** `gal` (Photos add-only permission).
- **Save to Files:** `NSSavePanel` through Pigeon `FileExportService`, defaulting to `~/Downloads`.
- **Show in Finder:** extra action on macOS (`NSWorkspace.activateFileViewerSelecting`).

## Drag and Drop

- Dropping a URL (from a browser) on the window → Download tab, link pasted, preview opens.
- Dropping files → Convert tab with them as the input.

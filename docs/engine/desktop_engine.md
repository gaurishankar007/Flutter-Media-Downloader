# Desktop Engine (macOS, Windows, Linux)

> Status: implemented. macOS is tested on the development Mac; Windows and Linux are built in CI but not yet tested on devices. Dart: `desktop_media_engine.dart`, `desktop_engine_binaries.dart`. No native code for the engine itself.

The three desktops share one engine: `DesktopMediaEngine` (`@LazySingleton(as: MediaEngine, env: PlatformEnv.desktop)`) runs bundled yt-dlp / ffmpeg binaries as `dart:io` processes. Everything that differs per OS (where the binaries are, their names, the environment, how to stop a process tree) lives in `DesktopEngineBinaries`. macOS specifics (bundling, signing, sandbox, Photos) are in [macOS Engine](macos_engine.md).

## Binaries

| | macOS | Windows | Linux |
| --- | --- | --- | --- |
| Source folder (not committed, only `.gitkeep`) | `macos/Runner/Resources/bin/` | `windows/engine/bin/` | `linux/engine/bin/` |
| In the built app | `Contents/Resources/bin/` | `bin\` next to `media_tool.exe` | `bin/` next to `media_tool` in the bundle |
| Copied by | `macos/scripts/bundle_engine_binaries.sh` (Xcode build phase) | an `install(DIRECTORY …)` rule in `windows/CMakeLists.txt` | the same rule in `linux/CMakeLists.txt` (keeps the executable bits) |
| yt-dlp | `yt-dlp_macos` (universal2) | `yt-dlp.exe` | `yt-dlp_linux` (`yt-dlp_linux_aarch64` saved under that name on ARM) |
| ffmpeg, ffprobe | ffmpeg.martin-riedl.de static builds | BtbN/FFmpeg-Builds `ffmpeg-master-latest-win64-gpl` | BtbN/FFmpeg-Builds `ffmpeg-master-latest-linux64-gpl` / `linuxarm64-gpl` |
| deno (optional, YouTube JS challenges) | `deno` | `deno.exe` | `deno` |

yt-dlp is always the official standalone build from https://github.com/yt-dlp/yt-dlp/releases (latest), checked against `SHA2-256SUMS`. The BtbN GPL builds include libx264, x265, libmp3lame and libwebp.

### Fetch scripts

Run once after cloning, and again to refresh:

```bash
macos/scripts/fetch_engine_binaries.sh [--universal] [--with-deno]
linux/scripts/fetch_engine_binaries.sh [--with-deno]                              # this machine's arch
powershell -ExecutionPolicy Bypass -File windows\scripts\fetch_engine.ps1 [-WithDeno]   # x64
```

The Windows script also clears the "downloaded from the internet" mark (`Unblock-File`) so the binaries run without prompts. A build without the binaries still succeeds; the engine then fails to start with "Engine binaries missing in <bin>".

## Running

- `Process.run` for probe, `--version`, `-encoders`, `-U` and image jobs; `Process.start` for downloads and ffmpeg jobs, reading stdout line by line as UTF-8 and keeping the last 4000 characters of stderr for errors.
- **Environment** (`DesktopEngineBinaries.environment`): `bin` goes first on `PATH` (`;`-separated on Windows). macOS adds Homebrew paths (GUI apps start with a bare `PATH`, and a non-bundled `deno` may live there). `LANG` / `LC_ALL` are `en_US.UTF-8` on macOS and `C.UTF-8` on Linux; all three set `PYTHONUTF8=1` and `PYTHONIOENCODING=utf-8`, so titles and file names survive.
- **Extra yt-dlp args** the shared builder can't know: `--ffmpeg-location <bin>`, and `--js-runtimes deno:<bin>/deno` when deno is bundled.
- **Cancel:** yt-dlp is a bootloader with Python (and ffmpeg) below it, so the whole tree is stopped. macOS / Linux: SIGTERM to the process and its descendants (`pgrep -P`), SIGKILL after 3 s. Windows: `taskkill /PID <pid> /T /F` (console programs have no graceful stop).
- **No console windows on Windows:** yt-dlp and ffmpeg are console programs, and a GUI app without a console would open one window per process. `windows/runner/main.cpp` therefore allocates one hidden console at startup (`AllocConsole` + `ShowWindow(SW_HIDE)`) when it isn't started from a terminal or debugger; the child processes share it. It can flash briefly when the app opens.
- **Hardware encoders:** the iPhone re-encode and compression use `libx264` on Windows and Linux (no NVENC / QSV / AMF / VAAPI yet), so they are slower than on macOS.

## Updating yt-dlp

The bundled binary may be read-only (signed macOS bundle, `Program Files`), so before first use it's copied to `<app support>/engine/` (`yt-dlp_macos`, `yt-dlp.exe` or `yt-dlp_linux`, `chmod 755` except on Windows), and that copy runs. `yt-dlp -U` updates it in place. If the copy is missing or `--version` fails, it's copied again; if that still fails, the bundled binary runs (and **Update** reports a failure).

## Images

`flutter_image_compress` has no Windows or Linux plugin, so `FfmpegImageService` and `FfmpegImageConvertService` (env windows, linux) run the bundled ffmpeg (`FfmpegCommandBuilder.image`, see [ffmpeg Recipes](ffmpeg_recipes.md#images)). They write JPG, PNG and WebP; no HEIC, and metadata is always dropped.

## Platform Services

| Service | Windows | Linux |
| --- | --- | --- |
| Save to Photos (`GalleryService`) | `gal`: the Pictures library, `MediaTool` album | `LinuxGalleryService`: copies into `MediaTool/` in the Pictures or Videos folder (`xdg-user-dir`, else `~/Pictures`, `~/Videos`), never overwriting (`name (2).mp4`) |
| Save to Files (`FileExportService`) | `DesktopFileExportService`: the common save dialog (`file_picker`), then a streamed copy | Same, with the desktop portal, `zenity` or `kdialog` (one must be installed) |
| Share | `share_plus` | `share_plus` |
| Playback | `video_player_win` (Media Foundation), registered automatically | None: the Library viewer shows "This file can't be played here" and the preview stays a thumbnail |
| Background work | No-op (desktops keep running) | No-op |
| Browser cookies | Firefox (Chrome's app-bound encryption blocks other programs) | Chrome, Firefox |
| System tab | See [System](../features/system.md) | See [System](../features/system.md) |

## Window

Both runners title the window "Media Tool", open at 1100 × 760 and keep a 600 × 600 minimum (Windows: `WM_GETMINMAXINFO`, scaled for DPI; Linux: GTK geometry hints), matching macOS. Windows uses the generated `app_icon.ico` (`flutter_launcher_icons`); Linux loads `data/app_icon.png` (`linux/runner/resources/app_icon.png`, installed by CMake). Linux's application id is `com.gss.mediatool`.

## Releases

CI builds `MediaTool-<ver>-windows-x64.zip` (a `Media Tool` folder with the exe, DLLs, `data\` and `bin\`) and `MediaTool-<ver>-linux-x64.tar.gz` (a `MediaTool` folder; tar keeps the executable bits a zip would lose). Both are x64 only. See [Development: Releases](../architecture/development.md#releases).

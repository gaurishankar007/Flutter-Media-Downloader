# Troubleshooting

Known problems and their fixes. Add to this as they come up.

| Problem | Cause | Fix |
| --- | --- | --- |
| Downloads from one site suddenly fail with "The site changed" | The site changed its page; yt-dlp hasn't been updated in the app | Tap **Update engine** on the failed job card, or Settings → Engine → **Update**. If it still fails, check yt-dlp's GitHub issues for that site. |
| Instagram/TikTok/Facebook/X **photos** fail with "The site changed and this post can't be read" | The Dart extractor's page parsing is out of date | Open the post in a browser, compare the page with what the parser expects, and update the parser. See [Photo Extractors](../extractors/photo_extractors.md). |
| "This post needs you to be logged in" | Private post, Story, or login wall (Instagram often asks for it) | Import cookies for that site (Settings → Cookies, or **Cookies** on the failed job card). |
| YouTube: "YouTube wants a sign-in" | YouTube's bot check on this network | Import YouTube cookies, or wait and retry. |
| YouTube offers few qualities on a desktop or iOS | yt-dlp needs a JavaScript runtime for YouTube's challenges | macOS: install deno (Homebrew) or fetch with `macos/scripts/fetch_engine_binaries.sh --with-deno`; Windows / Linux: fetch with `-WithDeno` / `--with-deno` (release builds bundle it). iOS has no JS runtime, so YouTube formats stay limited. See [macOS Engine](../engine/macos_engine.md), [iOS Engine](../engine/ios_engine.md). |
| Video won't play in the iPhone Photos app | HEVC without `hvc1` tag, or VP9/AV1 kept | Keep "iPhone-compatible" on; check the re-encode adds `-tag:v hvc1`. See [ffmpeg Recipes](../engine/ffmpeg_recipes.md). |
| 4K download is very slow on Android | VP9/AV1 → H.264/HEVC re-encode on the phone's CPU | Expected. Pick 1080p for a fast remux, or turn iPhone-compatible off. |
| Android: engine fails to start on first launch | youtubedl-android native libs not extracted | Check the `jniLibs` legacy packaging settings in `android/app/build.gradle.kts` per the library README. See [Android Engine](../engine/android_engine.md). |
| macOS: build fails or "yt-dlp_macos can't be opened" | Binaries missing, quarantined or unsigned | Run `macos/scripts/fetch_engine_binaries.sh`; the `bundle_engine_binaries.sh` build phase clears quarantine and signs each binary ad hoc. |
| Windows / Linux: "Engine binaries missing" | `bin/` wasn't fetched before the build, or the app folder was split up | Run `windows/scripts/fetch_engine.ps1` or `linux/scripts/fetch_engine_binaries.sh` and build again. A release must stay one folder (`bin/` and `data/` next to the executable). See [Desktop Engine](../engine/desktop_engine.md). |
| Windows: "Windows protected your PC" | The app isn't code-signed | **More info → Run anyway**. Downloaded binaries can also be blocked: the fetch script runs `Unblock-File`. |
| Windows: Firefox is the only browser for cookies | Chrome 127+ encrypts cookies so only Chrome can read them | Use Firefox, or import a cookies.txt for the site. |
| Linux: Save to Files does nothing | No file dialog backend | Install `xdg-desktop-portal` (with a GTK or KDE backend), `zenity` or `kdialog`. |
| Linux: videos don't play in the app | There is no `video_player` for Linux | Expected: Share or Save the file and play it in another app. |
| Windows / Linux: re-encoding is slow | Only `libx264` (CPU) is used there | Expected. Pick a quality that remuxes, or turn iPhone-compatible off. |
| iOS: build fails on missing frameworks | `ios/Frameworks/` not fetched | Run `ios/scripts/fetch_engine.sh`, then build again. |
| iOS: long download stops in the background | iOS gives ~30 s in the background (no foreground service like Android) | Keep the app open; tap **Retry**. |
| Download shows "The app was closed during this download" | The app was killed (or swiped away) while the job ran | Tap **Retry**. |

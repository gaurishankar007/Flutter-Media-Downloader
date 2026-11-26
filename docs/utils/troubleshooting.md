# Troubleshooting

Known problems and their fixes. Add to this as they come up.

| Problem | Cause | Fix |
| --- | --- | --- |
| Downloads from one site suddenly fail with "The site changed" | The site changed its page; yt-dlp hasn't been updated in the app | Settings → Engine → **Update**. If it still fails, check yt-dlp's GitHub issues for that site. |
| Instagram/TikTok/Facebook **photos** fail but videos work | The Dart extractor's page parsing is out of date | Open the post in a browser, compare the page with what the parser expects, and update the parser. See [Photo Extractors](../extractors/photo_extractors.md). |
| "This post needs you to be logged in" | Private post, Story, or login wall | Import cookies for that site (Settings → Cookies). |
| YouTube: "Sign in to confirm you're not a bot" | YouTube's bot check on this network | Import YouTube cookies, or wait and retry. |
| Video won't play in the iPhone Photos app | HEVC without `hvc1` tag, or VP9/AV1 kept | Keep "iPhone-compatible" on; check the re-encode adds `-tag:v hvc1`. See [ffmpeg Recipes](../engine/ffmpeg_recipes.md). |
| 4K download is very slow on Android | VP9/AV1 → HEVC re-encode on the phone's CPU | Expected. Pick 1080p for a fast remux, or turn iPhone-compatible off. |
| Android: engine fails to start on first launch | youtubedl-android native libs not extracted | Check `extractNativeLibs` / legacy JNI packaging per the library README. See [Android Engine](../engine/android_engine.md). |
| macOS: "yt-dlp_macos can't be opened" / killed at launch | Binary not signed with hardened runtime, or quarantined | Sign each binary in the build phase. In development: `xattr -d com.apple.quarantine macos/Runner/Resources/bin/*`. |
| iOS: long download stops in the background | iOS gives ~30 s in the background | Keep the app open; tap **Retry** (yt-dlp resumes where it can). |
| Library shows items whose file is gone | File deleted outside the app | `LibraryRepository.reconcile()` removes them on the next launch. |

# Site Support

> Checked with yt-dlp 2026.11.23 and gallery-dl 1.32.21 during planning. Re-check when updating.

| Site | Video / audio | Photos | Route |
| --- | --- | --- | --- |
| YouTube | ✅ incl. 4K (VP9/AV1 only above 1080p) and Shorts | n/a | yt-dlp |
| Facebook | ✅ videos and Reels; private posts need cookies | ❌ in yt-dlp → `FacebookPhotoExtractor` (Dart). Many photo posts need cookies | yt-dlp + Dart |
| Instagram | ✅ posts, Reels; Stories need cookies; `instagram:user` (whole profile) **currently broken** | ❌ in yt-dlp (`There is no video in this post`) → `InstagramPhotoExtractor` (Dart, works without login) | yt-dlp + Dart |
| X / Twitter | ✅ tweets with video, Spaces (audio) | Tweet images via yt-dlp metadata / `og:image` | yt-dlp (+ Dart for images) |
| TikTok | ✅ `TikTok` and `vm.tiktok` short links, `tiktok:user`, `tiktok:collection`. `tiktok:sound`, `tiktok:tag`, `tiktok:effect` **currently broken** | ❌ in yt-dlp → `TikTokPhotoExtractor` (Dart); ✅ gallery-dl `tiktok:post` / `tiktok:vmpost` as fallback | yt-dlp + Dart / gallery-dl |
| Threads | ❌ no yt-dlp extractor → `ThreadsExtractor` (Dart) for videos | `ThreadsExtractor` (Dart) | Dart |

Only single posts are in scope for v1. Whole profiles, playlists and collections aren't offered (the probe uses `--no-playlist`).

## Logged-in Content

Some posts need the user's login (private Facebook posts, Instagram Stories, some YouTube videos behind a bot check). The app supports **importing cookies**:

- A Netscape `cookies.txt` file per site (exported with a browser extension), on all platforms.
- macOS only: `--cookies-from-browser` (Safari, Chrome, Firefox).

Cookies are only ever sent to the site they belong to, are stored in the app's private folder, and never leave the device. See [Settings: Cookies](../features/settings.md#cookies).

## When a Site Breaks

1. Update the engine (Settings → Engine → Update). Most breakages are fixed in yt-dlp within days.
2. Dart extractors break when Meta/TikTok change their pages. Each extractor is one isolated file, so fixing it means updating that parser. See [Photo Extractors](../extractors/photo_extractors.md).

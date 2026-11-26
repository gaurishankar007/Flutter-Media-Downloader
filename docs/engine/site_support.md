# Site Support

> Checked with yt-dlp 2026.11.23 during planning. Re-check when updating.

`Site` (`lib/domain/models/site.dart`) lists the supported sites and their domains; `UrlUtils.detectSite` matches a link's host (subdomains such as `www.`, `m.`, `vm.`, `music.` included). Short links (see `UrlUtils.isShortLink`, incl. Facebook `/share/` links) are followed in Dart first. Which route a link takes is decided by `ResolveLinkUseCase`; see [Photo Extractors](../extractors/photo_extractors.md#routing-a-link).

| Site | Video / audio | Photos | Route |
| --- | --- | --- | --- |
| YouTube | ✅ incl. 4K (VP9/AV1 only above 1080p) and Shorts | n/a | yt-dlp |
| Facebook | ✅ videos and Reels; private posts need cookies | ❌ in yt-dlp → `FacebookPhotoExtractor` (Dart) for photo URLs. Many photo posts need cookies | yt-dlp + Dart |
| Instagram | ✅ posts and Reels; Stories need cookies | ❌ in yt-dlp (`There is no video in this post`) → `InstagramPhotoExtractor` (Dart, public embed page, works without login). Carousels mixing photos and videos offer both | yt-dlp + Dart |
| X / Twitter | ✅ tweets with video, Spaces (audio) | `XImageExtractor` (Dart, X's public syndication/embed data, full size `name=orig`). A tweet with video and photos offers both | yt-dlp + Dart |
| TikTok | ✅ videos and `vm.tiktok` short links | ❌ in yt-dlp → `TikTokPhotoExtractor` (Dart) for `/photo/` URLs; optional **Save as video** turns the slideshow + music into one MP4 | yt-dlp + Dart |
| Threads | ❌ no yt-dlp extractor → `ThreadsExtractor` (Dart) for videos | `ThreadsExtractor` (Dart) | Dart |

Only single posts are in scope for v1. Whole profiles, playlists and collections aren't offered (the probe and download use `--no-playlist`).

There is **no gallery-dl fallback**: when a Dart extractor can't read a post (e.g. an Instagram post that needs a login), the link fails with a message suggesting cookies.

## Logged-in Content

Some posts need the user's login (private Facebook posts, Instagram Stories, some YouTube videos behind a bot check). The app supports **importing cookies** (Settings → Cookies):

- A Netscape `cookies.txt` file **per site**, stored as `cookies/<site>.txt` in the app's folder, on all platforms. yt-dlp gets it with `--cookies` only for links of that site, and the Dart extractors' `SiteHttpClient` sends it only to that site's own hosts.
- macOS only: `--cookies-from-browser safari|chrome|firefox`, used for a site that has no imported file.

Cookies are only ever sent to the site they belong to, stay in the app's private folder (excluded from backups on iOS) and never leave the device. See [Settings: Cookies](../features/settings.md#cookies).

## When a Site Breaks

1. Update the engine (Settings → Engine → Update). Most breakages are fixed in yt-dlp within days. A failed download card also offers **Update engine** and **Cookies** when the error suggests them.
2. Dart extractors break when Meta/TikTok/X change their pages. Each extractor is one isolated file, so fixing it means updating that parser. See [Photo Extractors](../extractors/photo_extractors.md).

# yt-dlp and ffmpeg Recipes

> The yt-dlp format/MP3 lines and the iPhone re-encode were tested on real downloads during planning (yt-dlp 2026.11.23). Compression presets are starting values: tune them on real files.

All of these are built in Dart by `YtDlpArgsBuilder` and `FfmpegCommandBuilder`, and unit-tested against expected argument lists.

## Download

**Best video ≤ chosen height, merged:**

```
yt-dlp -f "bv*[height<=2160]+ba/b" --merge-output-format mkv -o "%(title)s [%(height)sp].%(ext)s" URL
```

(The app uses its own `-o` template; see [Media Engine](media_engine.md#download-args).)

**iPhone-compatible, ≤ 1080p (no re-encode):** prefer H.264 + AAC so it's only a remux:

```
-f "bv*[height<=1080][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=1080]+ba/b" --merge-output-format mp4
```

**MP3:**

```
yt-dlp -f ba -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata -o "%(title)s.%(ext)s" URL
```

`--audio-quality 0` is best VBR. For the 192 / 128 kbps choices use `--audio-quality 192K` / `128K`.

## iPhone-compatible Re-encode

YouTube 1440p/4K only comes as VP9/AV1, so it has to be re-encoded to play in the iPhone Photos app:

```
ffmpeg -i in.mkv -c:v hevc_videotoolbox -q:v 65 -tag:v hvc1 -pix_fmt yuv420p \
       -c:a aac -b:a 192k -movflags +faststart out.mp4
```

- `-tag:v hvc1` is **required**, or Apple Photos refuses the file.
- If the downloaded streams are already H.264/HEVC + AAC, skip the re-encode and remux: `ffmpeg -i in.mkv -c copy -tag:v hvc1 -movflags +faststart out.mp4` (use `-tag:v hvc1` only for HEVC).

## Encoder Choice

`FfmpegCommandBuilder` picks the video encoder from `EngineInfo.encoders` (read from `ffmpeg -encoders` at init):

| Platform | First choice | Fallback |
| --- | --- | --- |
| iOS / macOS | `hevc_videotoolbox` (hardware) | `h264_videotoolbox` |
| Android | `hevc_mediacodec` (hardware) | `libx264 -preset veryfast` |

Hardware encoders take a bitrate (`-b:v`) or quality (`-q:v`, videotoolbox on Apple Silicon); `libx264` takes `-crf`. The builder handles both.

## Convert

| From → To | Command shape |
| --- | --- |
| Video → MP4 (codecs already H.264/HEVC + AAC) | `-c copy -movflags +faststart` |
| Video → MP4 (other codecs) | iPhone re-encode above |
| Video → MOV | same as MP4, `.mov` container |
| Video → MKV | `-c copy` (MKV takes almost anything) |
| Video → WebM | `-c:v libvpx-vp9 -crf 32 -b:v 0 -c:a libopus` (slow; only if the encoder exists, else the option is hidden) |
| Video → MP3 | `-vn -c:a libmp3lame -q:a 0` |
| Video → M4A | `-vn -c:a copy` if the audio is AAC, else `-c:a aac -b:a 192k` |

## Compress Video

Presets (`VideoCompressPreset`):

| Preset | libx264 CRF | videotoolbox `-q:v` | Bitrate fallback (1080p / 720p / 480p) | Audio |
| --- | --- | --- | --- | --- |
| High | 23 | 65 | 6 / 3.5 / 1.8 Mbps | AAC 160k |
| Medium | 28 | 55 | 4 / 2.5 / 1.2 Mbps | AAC 128k |
| Small | 32 | 45 | 2.5 / 1.5 / 0.8 Mbps | AAC 96k |

- Resolution: `-vf "scale=-2:<height>"`, only ever downscaling (never upscale a smaller source).
- **"Aim for about N MB"** (single pass): `videoBitrate = (N × 8 × 1024 × 1024 / durationSeconds) − audioBitrate`, then `-b:v <rate> -maxrate <1.5×rate> -bufsize <2×rate>`. Lands within roughly ±10%. If the result would be under ~300 kbps at the chosen resolution, warn and suggest a lower resolution.
- Exact-size two-pass encoding is **deferred** (later stage).

## Images

Photos are handled with `flutter_image_compress` (native encoders, fast), not ffmpeg:

- Download default: WebP/HEIC → **JPG quality 92**, with an option to keep the original.
- Convert: JPG ↔ PNG ↔ WebP ↔ HEIC. HEIC *output* works on iOS/macOS; on Android it depends on the device (Android 9+). If it isn't available, the HEIC option is hidden. (Check on real devices; drop to "later" if unreliable.)
- Compress: longest side (e.g. 4096 / 2048 / 1080) or a percentage, quality slider 40–100, **strip metadata** on by default (removes GPS location).

## TikTok Slideshow → Video (optional)

```
ffmpeg -framerate 1/3 -i img_%02d.jpg -i music.m4a \
       -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
       -c:v <encoder> -c:a aac -shortest -movflags +faststart out.mp4
```

Each image ~3 s, or spread evenly over the music's length (`framerate = images / audioSeconds`).

## Thumbnail Frame

```
ffmpeg -ss <10% of duration> -i in.mp4 -frames:v 1 -vf "scale=480:-2" -q:v 4 thumb.jpg
```

# yt-dlp and ffmpeg Recipes

> The yt-dlp format/MP3 lines and the iPhone re-encode were tested on real downloads during planning (yt-dlp 2026.11.23). Compression presets are starting values: tune them on real files.

All of these are built in Dart by `YtDlpArgsBuilder` and `FfmpegCommandBuilder` (`lib/data/services/platform/media_engine/builders/`). The platform engines only run them. Every long-running ffmpeg command starts with `-hide_banner -nostats -progress pipe:1 -y -i <input>` so progress arrives on stdout as `out_time_us=` / `speed=` lines.

## Download

The common args (output template, thumbnail, progress, cookies) are in [Media Engine: Download Args](media_engine.md#download-args). `<cap>` below is `[height<=N]` for a chosen quality, empty for Best.

**iPhone-compatible on, tier has H.264:** prefer H.264 + AAC so the MP4 is only a remux:

```
-f "bv*<cap>[vcodec^=avc1]+ba[ext=m4a]/bv*<cap>[vcodec^=avc1]+ba/b<cap>[vcodec^=avc1]/bv*<cap>+ba/b<cap>/b" --merge-output-format mp4
```

**iPhone-compatible on, no H.264 at that height** (YouTube 1440p/4K is VP9/AV1 only): take the best streams, then run the [iPhone re-encode](#iphone-compatible-re-encode):

```
-f "bv*<cap>+ba/b<cap>/b" --merge-output-format mkv
```

**iPhone-compatible off:** original codecs:

```
-f "bv*<cap>+ba/b<cap>/b" --merge-output-format mp4/mkv
```

**MP3:**

```
-f "ba/b" -x --audio-format mp3 --audio-quality <320|192|128>K --embed-thumbnail --add-metadata
```

## iPhone-compatible Re-encode

`FfmpegCommandBuilder.iphoneVideo` (after a download whose tier had no H.264; also the converter's fallback for MP4/MOV):

```
ffmpeg ... -i in.mkv <video args> -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart out.mp4
```

| Encoder | Video args |
| --- | --- |
| `hevc_videotoolbox` | `-c:v hevc_videotoolbox -q:v 65 -tag:v hvc1` |
| `hevc_mediacodec` | `-c:v hevc_mediacodec -b:v 20M / 12M / 8M -tag:v hvc1` (≥2000 / ≥1400 / smaller short side) |
| `h264_videotoolbox` | `-c:v h264_videotoolbox -q:v 65` |
| `libx264` | `-c:v libx264 -preset veryfast -crf 23` |

- `-tag:v hvc1` is **required** for HEVC, or Apple Photos refuses the file.
- When the streams are already H.264/HEVC (+ AAC), the converter only remuxes (see [Convert](#convert)).

## Encoder Choice

`FfmpegCommandBuilder.iphoneEncoders(available)` orders the encoders from `EngineInfo.encoders` (read from `ffmpeg -hide_banner -encoders` at init):

1. `hevc_videotoolbox` (iOS / macOS, hardware)
2. `hevc_mediacodec` (Android, hardware)
3. `h264_videotoolbox` (iOS / macOS)
4. `libx264` (always last, the safe fallback)

Only the ones the engine reports are used (plus `libx264`). The repositories build one command per encoder and try them in order: hardware encoders fail on some devices, so each is a fallback for the one before. Hardware encoders take a bitrate (`-b:v`, mediacodec) or a quality (`-q:v`, videotoolbox); `libx264` takes `-crf`.

## Convert

`ConvertRepositoryImpl._commands`:

| From → To | Command |
| --- | --- |
| Video → MP4 / MOV (video already H.264/HEVC) | `remux`: `-map 0:v:0 -map 0:a:0? -c copy [-tag:v hvc1 for HEVC] [-c:a aac -b:a 192k if the audio isn't AAC and iPhone-compatible is on] -movflags +faststart`; the iPhone re-encode is added as a fallback if the remux fails |
| Video → MP4 / MOV (other codecs) | iPhone re-encode above (one command per encoder) |
| Video → MKV | `remux`: `-c copy` (MKV takes almost anything) |
| Video → WebM | `-c:v libvpx-vp9 -crf 32 -b:v 0 -row-mt 1 -c:a libopus -b:a 128k` (slow; offered only when `libvpx-vp9` is in the encoder list) |
| Video / audio → MP3 | `-vn -map 0:a:0 -c:a libmp3lame -q:a 0` |
| Video / audio → M4A | `-vn -map 0:a:0 -c:a copy -movflags +faststart` if the audio is AAC, else `-c:a aac -b:a 192k` |

`-map 0:v:0 -map 0:a:0?` keeps only the first video and audio stream: subtitles and cover art often can't go into the new container. Audio files can only become MP3 or M4A.

## Compress Video

Output is always MP4. Presets (`VideoCompressPreset`):

| Preset | libx264 CRF | videotoolbox `-q:v` | Bitrate (1080p / 720p / 480p), for mediacodec | Audio |
| --- | --- | --- | --- | --- |
| High | 23 | 65 | 6 / 3.5 / 1.8 Mbps | AAC 160k |
| Medium | 28 | 55 | 4 / 2.5 / 1.2 Mbps | AAC 128k |
| Small | 32 | 45 | 2.5 / 1.5 / 0.8 Mbps | AAC 96k |

Above 1080p the bitrate grows with the pixel count.

- Resolution: `-vf "scale=-2:<height>"` (portrait: `scale=<height>:-2`, so the short side is scaled), only ever downscaling.
- **"Aim for about N MB"** (single pass): `videoKbps = N × 8 × 1024 × 1024 / durationSeconds / 1000 − audioKbps`, then `-b:v <rate>k -maxrate <1.5×rate>k -bufsize <2×rate>k` with any encoder. Below 300 kbps (`ConvertRequest.minVideoKbps`) the UI warns that the target is too small.
- HEVC output gets `-tag:v hvc1`; all output `-pix_fmt yuv420p -movflags +faststart`.
- Exact-size two-pass encoding is **deferred** (later stage).

## Images

Photos are handled with `flutter_image_compress` (native encoders, fast), not ffmpeg:

- **Download:** with **Convert photos to JPG** on (Settings), photo-post images that aren't JPG (WebP, HEIC, PNG, …) are re-encoded to **JPG quality 92** (`ImageService.toJpg`).
- **Convert** (`ImageConvertService`): to JPG, PNG, WebP or HEIC. HEIC output is hidden on Android (it depends on the device's hardware encoder; later), WebP output is hidden on macOS (the macOS plugin writes JPEG when asked for WebP).
- **Compress:** longest side 4096 / 2048 / 1080 px or a percentage, quality slider 40–100 (default 80), **strip metadata** on by default (removes GPS location; EXIF is only ever kept for JPG).

## TikTok Slideshow → Video (optional)

`FfmpegCommandBuilder.slideshow`, used for TikTok photo posts with **Save as video**:

```
ffmpeg ... -framerate 1/3 -start_number 1 -i <work>/%02d.jpg -i music.m4a \
       -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
       -r 30 <video args> -c:a aac -b:a 192k -shortest -movflags +faststart out.mp4
```

Each image is shown 3 s. Video args follow the [encoder table](#iphone-compatible-re-encode) (mediacodec at 6M, `libx264` adds `-tune stillimage`).

## Thumbnail Frame

```
ffmpeg -hide_banner -nostats -y -ss <10% of duration> -i in.mp4 -frames:v 1 -vf "scale=480:-2" -q:v 4 thumb.jpg
```

Used for converted videos and imported source videos. Downloads use yt-dlp's own thumbnail (`--write-thumbnail --convert-thumbnails jpg`).

## Reading a Local File

```
ffmpeg -hide_banner -i <file>
```

No output file, so ffmpeg prints the input summary to stderr and exits with an error; `FfmpegInfoParser` reads it. See [Media Engine: Reading Local Files](media_engine.md#reading-local-files).

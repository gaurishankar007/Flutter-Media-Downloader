# Convert & Compress

> Status: planned (v1 step 3). Feature folder: `lib/ui/features/convert/`.

Change a file's format, or make it smaller. It uses the same ffmpeg every engine already ships for downloads, so it's mostly UI and command building (`FfmpegCommandBuilder`). Images use `flutter_image_compress`.

## Screens and Widgets

```text
convert/
  models/
    convert_options.dart            # mode, target format, preset, height, target MB, image options
  providers/
    convert_source_notifier.dart    # picked input(s) + ffprobe info
    convert_options_notifier.dart   # choices, valid targets for the input, size estimate
    convert_job_notifier.dart       # running job + result (keep-alive)
  views/
    convert/
      convert_screen.dart           # steps 1-2
      widgets/ source_tiles.dart, source_preview.dart, mode_picker.dart, format_chips.dart, video_compress_options.dart, image_compress_options.dart, convert_button.dart
    convert_result/
      convert_result_screen.dart    # step 3
      widgets/ size_comparison.dart, result_actions.dart
```

## Steps

1. **Pick** — three tiles: **From Library** (opens a Library picker sheet using the same grid), **From Photos** (`image_picker`), **From Files** (`file_picker`). On macOS, files can also be dropped on the screen. Picked files from Photos/Files are copied into `work/` first.
2. **Choose** — `SegmentedPicker`: **Convert** / **Compress**.
   - Convert: format chips valid for the input (see table below).
   - Compress video: preset (High / Medium / Small), max resolution (Original / 1080p / 720p / 480p), optional "Aim for about N MB".
   - Compress image: longest side or %, quality slider, strip metadata (on by default).
   - The button shows an estimate: "Convert · about 48 MB".
3. **Result** — before → after sizes with the percentage saved, a preview, and **Save to Photos**, **Save to Files**, **Share**, **Done**. The output is already in the Library (`origin: convert`); the original is untouched.

## Formats

| Input | Convert to |
| --- | --- |
| Video | MP4, MOV, MKV, WebM (if the encoder exists), MP3, M4A |
| Audio | MP3, M4A |
| Image | JPG, PNG, WebP, HEIC (where supported) |

Commands for each are in [ffmpeg Recipes](../engine/ffmpeg_recipes.md#convert).

## Providers

| Provider | Owns | Key methods |
| --- | --- | --- |
| `convertSourceProvider` (`ConvertSourceNotifier`) | The input file, its `LocalMediaInfo` (from `MediaEngine.probeFile`) | `pickFromLibrary(id)`, `pickFromPhotos()`, `pickFromFiles()`, `setDropped(path)`, `clear()` |
| `convertOptionsProvider` (`ConvertOptionsNotifier`) | `ConvertOptions` and the size estimate | `setMode()`, `setFormat()`, `setPreset()`, `setHeight()`, `setTargetMb()`, `setImageOptions()` |
| `convertJobProvider` (`ConvertJobNotifier`, keep-alive) | The running job's progress and the result `LibraryItem` | `start()`, `cancel()` |

Conversions use the same `JobProgress` model and the same 1-at-a-time ffmpeg slot as downloads, so a download's iPhone re-encode and a conversion never run together.

## Deferred (later stage)

- Exact target-size two-pass video compression (v1 has single-pass "about N MB").
- Batch conversion of many files at once.
- HEIC output on Android if it turns out unreliable across devices.

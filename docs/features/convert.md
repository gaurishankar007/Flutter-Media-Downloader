# Convert & Compress

> Status: built (v1 step 3), not yet tested on every device. Feature folder: `lib/ui/features/convert/`.

Change a file's format, or make it smaller. Video and audio use the same ffmpeg every engine already ships for downloads (commands from `FfmpegCommandBuilder`); images use `flutter_image_compress` (`ImageConvertService`).

## Screens and Widgets

Everything happens on one screen (`ConvertScreen`, the Convert tab); there is no separate result route.

```text
convert/
  models/
    convert_options.dart            # mode, target format, preset, max height, target MB, image options, iPhone toggle
  providers/
    convert_source/   convert_source_notifier.dart    # picked file + what it can become (keep-alive)
    convert_options/  convert_options_notifier.dart   # choices + the ConvertRequest / size estimate
    convert_job/      convert_job_notifier.dart       # running job + result (keep-alive)
  views/convert/
    convert_screen.dart
    widgets/ source_tiles.dart, source_tile.dart, library_picker_sheet.dart, format_overview_card.dart, format_row.dart,
             source_preview.dart, mode_picker.dart, format_chips.dart, video_compress_options.dart,
             image_compress_options.dart, convert_button.dart, convert_job_panel.dart,
             convert_result_section.dart, size_comparison.dart, size_column.dart, result_actions.dart
```

The screen is a `ScreenScrollView`; its `bottomAction` (pinned above the nav bar) is the **Convert / Compress** button while choosing, and `ResultActions` once the job is done.

## Steps

1. **Pick** — three tiles (`SourceTiles`):
   - **From Library**: `LibraryPickerSheet` (a Library grid in a bottom sheet). The Library file is read in place, never copied or deleted.
   - **From Photos**: `file_picker` with `FileType.media`.
   - **From Files**: `file_picker` (any file).

   Picked files are copied into their own `work/source-<uuid>/` folder first (the original is never touched) and the picker's temporary copies are cleared. There is no drag-and-drop target on macOS yet. Below the tiles, `FormatOverviewCard` lists what can be converted.
2. **Choose** — `SourcePreview` (the picked file with **Change**), then `ModePicker` (**Convert** / **Compress**; Compress only for video and images).
   - Convert: `FormatChips` with the valid targets (table below). For MP4 / MOV from a source whose video isn't H.264/HEVC, an **iPhone-compatible** switch.
   - Compress video: preset (High / Medium / Small), max resolution (Original + 1080p / 720p / 480p below the source), optional "Aim for about N MB" slider with a "too low" warning. Output is MP4.
   - Compress image: Original / longest side (4096 / 2048 / 1080 below the source) / 75 / 50 / 25 %, quality slider (not for PNG), strip metadata (on by default). Output keeps the source's format when the image encoder can write it, else JPG.
   - The pinned button shows an estimate when one exists: "Convert · about 48 MB". Images have no estimate.
3. **Run** — `ConvertJobPanel`: a `JobCard` with "Waiting for another conversion to finish…" (the ffmpeg slot), percent, ETA and **Cancel**; on failure or cancel, **Try again**.
4. **Result** — `ConvertResultSection` (preview + before → after sizes via `SizeComparison`) with the pinned `ResultActions`: **Save to Photos** (not for audio), **Save to Files**, **Share**, **Done** (forgets the job and the pick). The output is already in the Library (`origin: 'convert'`, keeping the source item's site, uploader and URL); the original is untouched.

## Reading the Source

`ConvertRepositoryImpl` builds a `LocalMediaInfo` for the picked file:

- **Images** (by extension or a Library photo): size from `ImageConvertService.sizeOf`; no engine needed.
- **Video / audio:** there is no `MediaEngine.probeFile`. The repository runs `FfmpegCommandBuilder.probe` (`ffmpeg -i <file>`, which "fails" without an output) and parses the stderr of `EngineFailed` with `FfmpegInfoParser`: duration, video/audio codecs, size, audio bitrate. A video without a Library thumbnail gets one from a frame at 10%. Unreadable files fail with `ConvertMessages.unreadable`.
- The engine is started once (`init()`) to learn its encoder list, which decides WebM and the H.264/HEVC encoder order.

## Formats

| Input | Convert to |
| --- | --- |
| Video | MP4, MOV, MKV, WebM (only if ffmpeg has `libvpx-vp9`), MP3 / M4A (when it has audio) |
| Audio | MP3, M4A |
| Image | JPG, PNG, WebP (not on macOS: the plugin writes JPEG for WebP), HEIC (not on Android: needs a hardware encoder) |

The source's own format is left out. MP4 / MOV remux (`-c copy`) when the video is already iPhone-compatible, and fall back to an iPhone re-encode otherwise; each ffmpeg command list is tried in order, so a failing hardware encoder falls back to the next. Commands are in [ffmpeg Recipes](../engine/ffmpeg_recipes.md#convert).

## Providers

| Provider | Owns | Key methods |
| --- | --- | --- |
| `convertSourceProvider` (`ConvertSourceNotifier`, keep-alive) | The `LocalMediaInfo`, its valid targets and compress format | `pickFromLibrary(id)`, `pickFromPhotos()`, `pickFromFiles()`, `setDropped(path)` (unused: no drop target yet), `clear()` |
| `convertOptionsProvider` (`ConvertOptionsNotifier`) | `ConvertOptions` and the resulting `ConvertRequest` (with `estimatedBytes`); rebuilt for each new source | `setMode()`, `setFormat()`, `setPreset()`, `setHeight()`, `setTargetMb()`, `toggleTargetMb()`, `setImageSize()`, `setImageQuality()`, `setStripMetadata()`, `setIphoneCompatible()` |
| `convertJobProvider` (`ConvertJobNotifier`, keep-alive) | The running job's `JobProgress`, the result `LibraryItem` and its thumbnail | `start(request)`, `cancel()`, `reset()`, `saveToPhotos()`, `saveToFiles()`, `share()` |

- **Follows the Library and Settings.** `ConvertSourceNotifier` and `ConvertJobNotifier` watch `LibraryRepository.watchItems()`: deleting a Library-picked source in the Library clears the pick, and deleting the result's Library item resets the result card, so Convert never offers a missing file. Both react only to real removals (an id in the previous emission but not the current one). `ConvertOptionsNotifier` listens to the global **iPhone-compatible** setting and applies a change to the file already picked; the per-file switch still overrides it afterwards.

`ConvertMediaUseCase` runs the job: `ConvertRepository.run` (ffmpeg or image encoder) → `save` (move into `downloads/`, thumbnail, Library row) → `done`, clearing `work/<jobId>/` at the end. Video/audio jobs wait for the shared `FfmpegSlot`, so a download's iPhone re-encode and a conversion never run together. The result's Save to Photos / Files show a toast but no "remove from app?" prompt.

## Deferred (later stage)

- Exact target-size two-pass video compression (v1 has single-pass "about N MB").
- Batch conversion of many files at once.
- HEIC output on Android, WebP output on macOS.
- Drag and drop onto the Convert screen on macOS.

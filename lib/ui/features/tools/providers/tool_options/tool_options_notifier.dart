import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/crop_rect.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/tools/models/crop_aspect.dart';
import 'package:media_tool/ui/features/tools/models/split_mode.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';

part 'tool_options_state.dart';

/// One [tool]'s options and the [ToolRequest] they make with its picked
/// files. Keep-alive per tool. See docs/features/tools.md#providers.
class ToolOptionsNotifier(final Tool tool) extends BaseNotifier<ToolOptionsState> {
  /// GIFs start as the first few seconds: long GIFs get very big.
  static const _gifSeconds = 5.0;
  static const _minSeconds = 0.2;

  /// Trim: how long a new clip starts out.
  static const _newClipSeconds = 5.0;

  /// Resize never makes a side longer than this.
  static const maxSide = 8000;

  List<LocalMediaInfo> _sources = const [];

  @override
  ToolOptionsState build() {
    _sources = ref.read(toolSourcesProvider(tool)).sources;
    ref.listen(toolSourcesProvider(tool).select((state) => state.sources), (previous, next) {
      final firstChanged = previous?.firstOrNull?.path != next.firstOrNull?.path;
      _sources = next;
      _emit(firstChanged ? _defaultsFor(next.firstOrNull, state) : state);
    });
    return _withRequest(_defaultsFor(_sources.firstOrNull, const ToolOptionsState()));
  }

  /// Applies a plain option change (page size, format, fps…).
  void change(ToolOptionsState Function(ToolOptionsState state) edit) =>
      runFlow('tools.changeOption', () => _emit(edit(state)));

  /// The part of the video, kept inside it and at least a moment long.
  void setRange(double start, double end) => runFlow('tools.setRange', () {
    final duration = _duration;
    _emit(state.copyWith(start: start.clamp(0, duration), end: end.clamp(0, duration)));
  });

  /// Video to GIF: the part starts at [seconds] (Start here).
  void setRangeStart(double seconds) =>
      runFlow('tools.setRangeStart', () => _emitRange(_range.withStart(seconds, _duration, _minSeconds)));

  /// Video to GIF: the part ends at [seconds] (End here).
  void setRangeEnd(double seconds) =>
      runFlow('tools.setRangeEnd', () => _emitRange(_range.withEnd(seconds, _duration, _minSeconds)));

  /// Trim: keep or remove the clips. Removing the whole-video clip a fresh
  /// pick starts with would remove everything, so it's dropped.
  void setTrimMode(TrimMode mode) => runFlow('tools.setTrimMode', () {
    final whole = _wholeClip;
    var clips = state.clips;
    if (mode == .remove && clips.length == 1 && clips.single == whole) {
      clips = const [];
    } else if (mode == .keep && clips.isEmpty && whole != null) {
      clips = [whole];
    }
    _emit(state.copyWith(trimMode: mode, clips: clips, selectedClip: 0));
  });

  /// Trim: a new clip at [at] seconds (where the preview is), selected.
  void addClip(double at) => runFlow('tools.addClip', () {
    final duration = _duration;
    if (duration <= 0) {
      return;
    }
    final length = math.min(_newClipSeconds, duration);
    final start = math.min(at.clamp(0, duration).toDouble(), duration - length);
    final clips = [...state.clips, VideoClip(start: start, end: start + length)];
    _emit(state.copyWith(clips: clips, selectedClip: clips.length - 1));
  });

  void selectClip(int index) => runFlow('tools.selectClip', () {
    if (index >= 0 && index < state.clips.length) {
      _emit(state.copyWith(selectedClip: index));
    }
  });

  void removeClip(int index) => runFlow('tools.removeClip', () {
    if (index < 0 || index >= state.clips.length) {
      return;
    }
    final clips = [...state.clips]..removeAt(index);
    final selected = state.selectedClip > index ? state.selectedClip - 1 : state.selectedClip;
    _emit(state.copyWith(clips: clips, selectedClip: math.max(0, math.min(selected, clips.length - 1))));
  });

  /// Trim: both ends of clip [index] (the range slider), kept inside the video.
  void setClip(int index, double start, double end) => runFlow('tools.setClip', () {
    final duration = _duration;
    _replaceClip(index, VideoClip(start: start.clamp(0, duration), end: end.clamp(0, duration)));
  });

  /// Trim: clip [index] starts at [seconds]. Past its end, the clip moves
  /// there keeping its length.
  void setClipStart(int index, double seconds) => runFlow('tools.setClipStart', () {
    if (_clipAt(index) case final clip?) {
      _replaceClip(index, clip.withStart(seconds, _duration, _minSeconds));
    }
  });

  /// Trim: clip [index] ends at [seconds]. Before its start, the clip moves
  /// there keeping its length.
  void setClipEnd(int index, double seconds) => runFlow('tools.setClipEnd', () {
    if (_clipAt(index) case final clip?) {
      _replaceClip(index, clip.withEnd(seconds, _duration, _minSeconds));
    }
  });

  void rotateImage(int quarterTurns) =>
      runFlow('tools.rotateImage', () => _emit(state.copyWith(quarterTurns: (state.quarterTurns + quarterTurns) % 4)));

  void rotatePage(int index) => runFlow('tools.rotatePage', () {
    final pages = [...state.pages];
    pages[index] = pages[index].rotated();
    _emit(state.copyWith(pages: pages));
  });

  void deletePage(int index) => runFlow('tools.deletePage', () {
    _emit(state.copyWith(pages: [...state.pages]..removeAt(index)));
  });

  /// Moves the page at [from] to [to] (ReorderableGridView indexes).
  void reorderPages(int from, int to) => runFlow('tools.reorderPages', () {
    final pages = [...state.pages];
    final moved = pages.removeAt(from);
    pages.insert(to > from ? to - 1 : to, moved);
    _emit(state.copyWith(pages: pages));
  });

  /// Every page back, in order, unrotated.
  void resetPages() => runFlow('tools.resetPages', () => _emit(state.copyWith(pages: _allPages(_sources.firstOrNull))));

  void _emit(ToolOptionsState next) => state = _withRequest(next);

  VideoClip get _range => VideoClip(start: state.start, end: state.end);

  void _emitRange(VideoClip range) => _emit(state.copyWith(start: range.start, end: range.end));

  double get _duration => _sources.firstOrNull?.durationSeconds ?? 0;

  /// The whole video as one clip; null before a video with a length is picked.
  VideoClip? get _wholeClip => _duration > 0 ? VideoClip(start: 0, end: _duration) : null;

  VideoClip? _clipAt(int index) => index >= 0 && index < state.clips.length ? state.clips[index] : null;

  void _replaceClip(int index, VideoClip clip) {
    if (_clipAt(index) == null) {
      return;
    }
    _emit(state.copyWith(clips: [...state.clips]..[index] = clip, selectedClip: index));
  }

  /// Options that follow the file: the whole video (a GIF's first seconds),
  /// every page, and a resize that suits the image.
  ToolOptionsState _defaultsFor(LocalMediaInfo? source, ToolOptionsState options) {
    final duration = source?.durationSeconds ?? 0;
    final longSide = math.max(source?.width ?? 0, source?.height ?? 0);
    return options.copyWith(
      start: 0,
      end: tool == .videoToGif ? math.min(duration, _gifSeconds) : duration,
      pages: _allPages(source),
      scalePercent: longSide >= 2400 ? 50 : 200,
      clips: tool == .trimVideo && duration > 0 && options.trimMode == .keep
          ? [VideoClip(start: 0, end: duration)]
          : const [],
      selectedClip: 0,
      password: '',
      ranges: '',
    );
  }

  static List<PdfPageRef> _allPages(LocalMediaInfo? source) => [
    for (var index = 0; index < (source?.pageCount ?? 0); index++) PdfPageRef(index: index),
  ];

  ToolOptionsState _withRequest(ToolOptionsState options) {
    final sources = _sources;
    final source = sources.firstOrNull;
    if (source == null || sources.length < tool.minSources) {
      return options.withRequest(null);
    }
    if (tool.input == .pdf && tool != .unlockPdf && sources.any((source) => source.encrypted)) {
      return options.withRequest(null, problem: ToolsMessages.lockedPdf);
    }
    final length = options.end - options.start;
    switch (tool) {
      case .imagesToPdf:
        return options.withRequest(
          ImagesToPdfRequest(
            sources: sources,
            paper: options.paper,
            orientation: options.orientation,
            margin: options.margin,
          ),
        );
      case .pdfToImages:
        return options.withRequest(PdfToImagesRequest(source: source, format: options.imageFormat, dpi: options.dpi));
      case .mergePdf:
        return options.withRequest(MergePdfRequest(sources: sources));
      case .splitPdf:
        final groups = _splitGroups(options, source.pageCount ?? 0);
        if (groups == null) {
          return options.withRequest(null, problem: ToolsMessages.rangesInvalid);
        }
        if (groups.isEmpty) {
          return options.withRequest(null);
        }
        return options.withRequest(
          SplitPdfRequest(source: source, groups: groups),
          partCount: groups.length,
        );
      case .organizePdf:
        if (options.pages.isEmpty) {
          return options.withRequest(null, problem: ToolsMessages.noPages);
        }
        return options.withRequest(OrganizePdfRequest(source: source, pages: options.pages));
      case .compressPdf:
        return options.withRequest(CompressPdfRequest(source: source, level: options.compressLevel));
      case .unlockPdf:
        if (source.encrypted && options.password.isEmpty) {
          return options.withRequest(null);
        }
        return options.withRequest(UnlockPdfRequest(source: source, password: options.password));
      case .videoToGif:
        if (length < _minSeconds) {
          return options.withRequest(null, problem: ToolsMessages.noLength);
        }
        return options.withRequest(
          VideoToGifRequest(
            source: source,
            startSeconds: options.start,
            endSeconds: options.end,
            fps: options.fps,
            width: options.gifWidth,
          ),
        );
      case .imagesToGif:
        return options.withRequest(
          ImagesToGifRequest(sources: sources, secondsPerImage: options.secondsPerImage, width: options.gifWidth),
        );
      case .gifToVideo:
        return options.withRequest(GifToVideoRequest(source: source));
      case .trimVideo:
        if (options.clips.isEmpty) {
          return options.withRequest(
            null,
            problem: options.trimMode == .keep ? ToolsMessages.addClipToKeep : ToolsMessages.addClipToRemove,
          );
        }
        if (options.clips.any((clip) => clip.length < _minSeconds)) {
          return options.withRequest(null, problem: ToolsMessages.noLength);
        }
        final request = TrimVideoRequest(
          source: source,
          clips: VideoClip.merged(options.clips),
          mode: options.trimMode,
          separate: options.separateClips,
          exact: options.exactCut,
        );
        if (request.keptSeconds < _minSeconds) {
          return options.withRequest(null, problem: ToolsMessages.removesEverything);
        }
        return options.withRequest(request);
      case .muteVideo:
        return options.withRequest(MuteVideoRequest(source: source));
      case .resizeImage:
        final (width, height) = (source.width, source.height);
        if (width == null || height == null) {
          return options.withRequest(null);
        }
        final size = scaledSize(width, height, options.scalePercent);
        return options.withRequest(
          ResizeImageRequest(source: source, width: size.width, height: size.height, format: options.outputFormat),
        );
      case .editImage:
        final (width, height) = (source.width, source.height);
        final ratio = options.cropAspect.ratio;
        final request = EditImageRequest(
          source: source,
          // The crop happens before the turn: a sideways turn swaps the shape.
          crop: ratio == null || width == null || height == null
              ? null
              : CropRect.centered(
                  aspect: options.quarterTurns.isOdd ? 1 / ratio : ratio,
                  imageWidth: width,
                  imageHeight: height,
                ),
          quarterTurns: options.quarterTurns,
          flipHorizontal: options.flipHorizontal,
          flipVertical: options.flipVertical,
          format: options.outputFormat,
        );
        if (request.changesNothing) {
          return options.withRequest(null, problem: ToolsMessages.noChanges);
        }
        return options.withRequest(request);
    }
  }

  /// [width] × [height] at [percent], even, with the long side at most [maxSide].
  static ({int width, int height}) scaledSize(int width, int height, int percent) {
    var scale = percent / 100;
    final longSide = math.max(width, height);
    if (longSide * scale > maxSide) {
      scale = maxSide / longSide;
    }
    return (width: math.max(2, (width * scale / 2).round() * 2), height: math.max(2, (height * scale / 2).round() * 2));
  }

  /// The parts Split makes, as 0-based page indexes, or null when the ranges
  /// can't be read.
  static List<List<int>>? _splitGroups(ToolOptionsState options, int pageCount) {
    switch (options.splitMode) {
      case .each:
        return [
          for (var page = 0; page < pageCount; page++) [page],
        ];
      case .every:
        final size = math.max(1, options.pagesPerPart);
        return [
          for (var first = 0; first < pageCount; first += size)
            [for (var page = first; page < math.min(first + size, pageCount); page++) page],
        ];
      case .ranges:
        if (options.ranges.trim().isEmpty) {
          return const [];
        }
        final groups = <List<int>>[];
        for (final part in options.ranges.split(',')) {
          final text = part.trim();
          if (text.isEmpty) {
            continue;
          }
          final bounds = text.split('-').map((bound) => int.tryParse(bound.trim())).toList();
          final (first, last) = switch (bounds) {
            [final single?] => (single, single),
            [final from?, final to?] => (from, to),
            _ => (0, -1),
          };
          if (first < 1 || last > pageCount || first > last) {
            return null;
          }
          groups.add([for (var page = first - 1; page < last; page++) page]);
        }
        return groups;
    }
  }
}

final toolOptionsProvider = NotifierProvider.family(ToolOptionsNotifier.new);

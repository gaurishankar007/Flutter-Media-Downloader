import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Trim video: keep the clips, or cut them out and join the rest.
enum TrimMode { keep, remove }

/// A part of a video, in seconds from its start.
final class const VideoClip({required final double start, required final double end}) extends Equatable {
  /// Gaps shorter than this between parts are dropped (less than a frame).
  static const _minGap = 0.05;

  double get length => end - start;

  /// Starts at [at] (inside `0`–[duration]), at least [minLength] long.
  /// Past the end, the clip moves there keeping its length.
  VideoClip withStart(double at, double duration, double minLength) {
    final start = at.clamp(0, duration).toDouble();
    final newEnd = start > end - minLength ? math.min(duration, start + length) : end;
    return VideoClip(start: math.max(0, math.min(start, newEnd - minLength)), end: newEnd);
  }

  /// Ends at [at] (inside `0`–[duration]), at least [minLength] long.
  /// Before the start, the clip moves there keeping its length.
  VideoClip withEnd(double at, double duration, double minLength) {
    final newEnd = at.clamp(0, duration).toDouble();
    final double newStart = newEnd < start + minLength ? math.max(0, newEnd - length) : start;
    return VideoClip(start: newStart, end: math.min(duration, math.max(newEnd, newStart + minLength)));
  }

  /// [clips] sorted by start, with overlapping or touching clips merged.
  static List<VideoClip> merged(List<VideoClip> clips) {
    final sorted = [...clips]..sort((a, b) => a.start.compareTo(b.start));
    final result = <VideoClip>[];
    for (final clip in sorted) {
      if (result.lastOrNull case final last? when clip.start <= last.end + _minGap) {
        result[result.length - 1] = VideoClip(start: last.start, end: math.max(last.end, clip.end));
      } else {
        result.add(clip);
      }
    }
    return result;
  }

  /// The parts of `0`–[duration] outside [clips] (which must be [merged]).
  static List<VideoClip> outside(List<VideoClip> clips, double duration) {
    final parts = <VideoClip>[];
    var cursor = 0.0;
    for (final clip in clips) {
      if (clip.start - cursor > _minGap) {
        parts.add(VideoClip(start: cursor, end: clip.start));
      }
      cursor = math.max(cursor, clip.end);
    }
    if (duration - cursor > _minGap) {
      parts.add(VideoClip(start: cursor, end: duration));
    }
    return parts;
  }

  @override
  List<Object?> get props => [start, end];
}

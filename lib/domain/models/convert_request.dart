import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/convert_mode.dart';
import 'package:media_tool/domain/models/image_compress_options.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/video_compress_preset.dart';

/// One conversion or compression of [source] into [format].
/// See docs/features/convert.md and docs/engine/ffmpeg_recipes.md.
final class const ConvertRequest({
  required final LocalMediaInfo source,
  required final ConvertMode mode,

  /// The output format (Compress keeps MP4 for video, the input's own
  /// format for images where it can be written).
  required final ConvertFormat format,
  final VideoCompressPreset preset = .medium,

  /// Compress video: the largest short side (1080, 720…); null keeps it.
  final int? maxHeight,

  /// Compress video: aim for about this many MB (single pass).
  final int? targetMb,
  final ImageCompressOptions imageOptions = const ImageCompressOptions(),

  /// Convert to MP4 / MOV: make sure the result plays in the iPhone Photos app.
  final bool iphoneCompatible = true,
}) extends Equatable {
  /// Below this the "about N MB" video looks bad; the screen warns.
  static const minVideoKbps = 300;

  /// What `-q:a 0` MP3s average.
  static const _mp3Kbps = 256;
  static const _aacKbps = 192;

  bool get isCompress => mode == .compress;

  /// The short side of the output video.
  int? get outputHeight => switch ((source.shortSide, maxHeight)) {
    (final side?, final max?) when isCompress && max < side => max,
    (final side, _) => side,
  };

  /// Compress video downscales (only ever down, never up).
  bool get scalesDown => isCompress && outputHeight != null && outputHeight != source.shortSide;

  /// Convert to MP4 / MOV / MKV by copying the streams (fast, no quality loss).
  bool get copiesVideo => switch (format) {
    .mkv => true,
    .mp4 || .mov => !isCompress && (source.hasIphoneVideo || !iphoneCompatible),
    _ => false,
  };

  /// Convert to MP4 / MOV that re-encodes the video for iPhone.
  bool get reencodesForIphone => !isCompress && (format == .mp4 || format == .mov) && !copiesVideo;

  int get audioKbps => isCompress ? preset.audioKbps : _aacKbps;

  /// "Aim for about N MB": the video bitrate that fills N MB, or null.
  int? get targetVideoKbps {
    final (mb, seconds) = (targetMb, source.durationSeconds);
    if (!isCompress || mb == null || seconds == null || seconds <= 0) {
      return null;
    }
    return (mb * 8 * 1024 * 1024 / seconds / 1000).round() - audioKbps;
  }

  /// The "about N MB" target is too small for a watchable video.
  bool get targetTooLow => (targetVideoKbps ?? minVideoKbps) < minVideoKbps;

  /// About how big the output will be, or null when there's no good guess (images, WebM).
  int? get estimatedBytes {
    final seconds = source.durationSeconds;
    int bytesFor(int kbps) => (kbps * 1000 / 8 * (seconds ?? 0)).round();
    if (seconds == null || seconds <= 0) {
      return copiesVideo ? source.sizeBytes : null;
    }
    if (isCompress) {
      if (source.kind != .video) {
        return null;
      }
      if (targetMb case final mb?) {
        return mb * 1024 * 1024;
      }
      return bytesFor(preset.videoKbps(outputHeight ?? 1080) + audioKbps);
    }
    return switch (format) {
      .mkv => source.sizeBytes,
      .mp4 || .mov when copiesVideo => source.sizeBytes,
      .mp4 || .mov => bytesFor(VideoCompressPreset.high.videoKbps(outputHeight ?? 1080) + _aacKbps),
      .mp3 => bytesFor(_mp3Kbps),
      .m4a => bytesFor(source.hasAacAudio ? source.audioKbps ?? _aacKbps : _aacKbps),
      _ => null,
    };
  }

  @override
  List<Object?> get props => [source, mode, format, preset, maxHeight, targetMb, imageOptions, iphoneCompatible];
}

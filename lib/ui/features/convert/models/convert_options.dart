import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/convert_format.dart';
import 'package:media_downloader/domain/models/convert_mode.dart';
import 'package:media_downloader/domain/models/image_compress_options.dart';
import 'package:media_downloader/domain/models/video_compress_preset.dart';

/// The choices on the Convert screen. See docs/features/convert.md#steps.
final class const ConvertOptions({
  final ConvertMode mode = .convert,

  /// Convert: the chosen target.
  final ConvertFormat? format,
  final VideoCompressPreset preset = .medium,

  /// Compress video: largest short side; null keeps the original.
  final int? maxHeight,

  /// Compress video: "Aim for about N MB"; null when off.
  final int? targetMb,
  final ImageCompressOptions image = const ImageCompressOptions(),
  final bool iphoneCompatible = true,
}) extends Equatable {
  ConvertOptions copyWith({
    ConvertMode? mode,
    ConvertFormat? format,
    VideoCompressPreset? preset,
    int? Function()? maxHeight,
    int? Function()? targetMb,
    ImageCompressOptions? image,
    bool? iphoneCompatible,
  }) => ConvertOptions(
    mode: mode ?? this.mode,
    format: format ?? this.format,
    preset: preset ?? this.preset,
    maxHeight: maxHeight == null ? this.maxHeight : maxHeight(),
    targetMb: targetMb == null ? this.targetMb : targetMb(),
    image: image ?? this.image,
    iphoneCompatible: iphoneCompatible ?? this.iphoneCompatible,
  );

  @override
  List<Object?> get props => [mode, format, preset, maxHeight, targetMb, image, iphoneCompatible];
}

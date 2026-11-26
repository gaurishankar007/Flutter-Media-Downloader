import 'package:equatable/equatable.dart';

/// Image compression: a size limit (longest side in pixels, or a percentage),
/// a quality and whether to strip metadata (GPS). See docs/engine/ffmpeg_recipes.md#images.
final class const ImageCompressOptions({
  /// Longest side in pixels; null keeps the size (unless [percent]).
  final int? longestSide,

  /// Scale in percent; used when [longestSide] is null.
  final int? percent,
  final int quality = 80,
  final bool stripMetadata = true,
}) extends Equatable {
  ImageCompressOptions copyWith({
    int? Function()? longestSide,
    int? Function()? percent,
    int? quality,
    bool? stripMetadata,
  }) => ImageCompressOptions(
    longestSide: longestSide == null ? this.longestSide : longestSide(),
    percent: percent == null ? this.percent : percent(),
    quality: quality ?? this.quality,
    stripMetadata: stripMetadata ?? this.stripMetadata,
  );

  @override
  List<Object?> get props => [longestSide, percent, quality, stripMetadata];
}

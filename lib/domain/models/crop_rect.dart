import 'package:equatable/equatable.dart';

/// A crop as fractions (0–1) of the image as it's shown (EXIF rotation applied).
final class const CropRect({
  required final double left,
  required final double top,
  required final double width,
  required final double height,
}) extends Equatable {
  /// A centred crop of [aspect] (width / height) inside an image of
  /// [imageWidth] × [imageHeight].
  factory centered({required double aspect, required int imageWidth, required int imageHeight}) {
    final imageAspect = imageWidth / imageHeight;
    if (aspect > imageAspect) {
      final height = imageAspect / aspect;
      return CropRect(left: 0, top: (1 - height) / 2, width: 1, height: height);
    }
    final width = aspect / imageAspect;
    return CropRect(left: (1 - width) / 2, top: 0, width: width, height: 1);
  }

  @override
  List<Object?> get props => [left, top, width, height];
}

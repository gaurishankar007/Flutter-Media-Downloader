import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:media_downloader/domain/models/convert_format.dart';

/// Image convert / compress with the platform's own encoders
/// (`flutter_image_compress`). Methods throw; repositories call them inside
/// `ErrorHandler.execute`. See docs/engine/ffmpeg_recipes.md#images.
abstract interface class ImageConvertService {
  /// The image formats this platform can write.
  List<ConvertFormat> get outputFormats;

  /// The decoded size (rotation applied), or null when it can't be decoded here.
  Future<({int width, int height})?> sizeOf(String path);

  /// Writes [input] as [format]. [shortSide] scales the short side down to
  /// that many pixels (null keeps the size). [keepMetadata] only works for JPG.
  Future<void> convert(
    String input,
    String output, {
    required ConvertFormat format,
    required int quality,
    int? shortSide,
    bool keepMetadata = false,
  });
}

@LazySingleton(as: ImageConvertService)
final class ImageConvertServiceImpl implements ImageConvertService {
  // The plugin scales down to at least minWidth × minHeight; this keeps the size.
  static const _noResize = 1 << 16;

  @override
  List<ConvertFormat> get outputFormats => [
    .jpg,
    .png,
    // The macOS plugin writes JPEG when asked for WebP.
    if (!Platform.isMacOS) .webp,
    // HEIC on Android depends on the device's hardware encoder: later.
    if (!Platform.isAndroid) .heic,
  ];

  @override
  Future<({int width, int height})?> sizeOf(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (width: descriptor.width, height: descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> convert(
    String input,
    String output, {
    required ConvertFormat format,
    required int quality,
    int? shortSide,
    bool keepMetadata = false,
  }) async {
    // A square box of the short side keeps the aspect ratio in either orientation.
    final size = shortSide ?? _noResize;
    final result = await FlutterImageCompress.compressAndGetFile(
      input,
      output,
      quality: quality,
      minWidth: size,
      minHeight: size,
      format: switch (format) {
        .png => .png,
        .webp => .webp,
        .heic => .heic,
        _ => .jpeg,
      },
      keepExif: keepMetadata && format == .jpg,
    );
    if (result == null) {
      throw UnsupportedError('Could not write the image');
    }
  }
}

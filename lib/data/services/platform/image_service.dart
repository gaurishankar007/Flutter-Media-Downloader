import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';

/// Image conversion with the platform's own encoders (`flutter_image_compress`),
/// not ffmpeg. Methods throw; repositories call them inside `ErrorHandler.execute`.
/// See docs/engine/ffmpeg_recipes.md (photos).
abstract interface class ImageService {
  /// Re-encodes [input] (WebP, HEIC, PNG…) as a JPG at full size.
  Future<void> toJpg(String input, String output, {int quality = 92});

  /// A small JPG whose short side is about [size] pixels.
  Future<void> thumbnail(String input, String output, {int size = 480});
}

@LazySingleton(as: ImageService)
final class ImageServiceImpl implements ImageService {
  // The plugin scales down to at least minWidth × minHeight; this keeps every
  // image at its own size.
  static const _noResize = 1 << 16;

  @override
  Future<void> toJpg(String input, String output, {int quality = 92}) =>
      _compress(input, output, quality: quality, size: _noResize);

  @override
  Future<void> thumbnail(String input, String output, {int size = 480}) =>
      _compress(input, output, quality: 80, size: size);

  Future<void> _compress(String input, String output, {required int quality, required int size}) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      input,
      output,
      quality: quality,
      minWidth: size,
      minHeight: size,
    );
    if (result == null) {
      throw UnsupportedError('Could not convert the image');
    }
  }
}

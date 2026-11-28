import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/crop_rect.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';

/// The image as Rotate & crop will save it: the area outside [crop] shaded,
/// then turned and flipped like the output.
class const EditPreview({
  super.key,
  required final String path,
  required final double aspectRatio,
  required final int quarterTurns,
  required final bool flipHorizontal,
  required final bool flipVertical,
  final CropRect? crop,
}) extends StatelessWidget {
  static const _maxHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    final image = AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: .expand,
        children: [
          Image(image: LocalMedia.image(path), fit: .fill),
          if (crop != null)
            CustomPaint(
              painter: _CropShade(crop: crop!, color: context.colors.scrim),
            ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _maxHeight),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: ColoredBox(
          color: context.colors.surfaceRaised,
          child: Center(
            // Turned first, then flipped, like ffmpeg's filters.
            child: Transform(
              alignment: .center,
              transform: Matrix4.diagonal3Values(flipHorizontal ? -1 : 1, flipVertical ? -1 : 1, 1),
              child: RotatedBox(quarterTurns: quarterTurns, child: image),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shades everything outside the crop.
final class _CropShade({required final CropRect crop, required final Color color}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inside = Rect.fromLTWH(
      crop.left * size.width,
      crop.top * size.height,
      math.max(1, crop.width * size.width),
      math.max(1, crop.height * size.height),
    );
    final path = Path()
      ..fillType = .evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(inside);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CropShade oldDelegate) => oldDelegate.crop != crop || oldDelegate.color != color;
}

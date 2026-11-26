import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A labelled slider with its current value on the right and an Aurora
/// active track (compression quality, target resolution).
class const AppSlider({
  super.key,
  required final String label,
  required final String valueLabel,
  required final double value,
  required final ValueChanged<double>? onChanged,
  final double min = 0,
  final double max = 1,
  final int? divisions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.bodyStrong)),
            Text(valueLabel, style: context.text.numeric.copyWith(color: colors.primaryText)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            trackShape: const _AuroraTrackShape(),
            inactiveTrackColor: colors.surfaceRaised,
            thumbColor: colors.onPrimary,
            overlayColor: colors.primary.withValues(alpha: 0.16),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            padding: const .symmetric(vertical: AppSpacing.md),
          ),
          child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
        ),
      ],
    );
  }
}

/// Rounded track: Aurora gradient up to the thumb, inactive colour after it.
final class const _AuroraTrackShape() extends SliderTrackShape with BaseSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    context.canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = sliderTheme.inactiveTrackColor!);
    final active = Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom);
    if (active.width > 0) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(active, radius),
        Paint()..shader = AppGradients.aurora.createShader(rect),
      );
    }
  }
}

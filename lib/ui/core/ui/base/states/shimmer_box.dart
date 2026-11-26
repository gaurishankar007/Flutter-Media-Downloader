import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A loading placeholder with a soft light sweeping across. Build the same
/// layout as the final content out of these. Static when animations are off.
class const ShimmerBox({
  super.key,
  final double? width,
  final double? height,
  final BorderRadius borderRadius = AppRadius.smAll,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(duration: const Duration(milliseconds: 1400));

    useEffect(() {
      if (reduceMotion) {
        controller.stop();
      } else {
        controller.repeat();
      }
      return null;
    }, [reduceMotion]);

    final base = colors.surfaceRaised;
    final highlight = Color.lerp(base, colors.textPrimary, context.isDark ? 0.08 : 0.5)!;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value * 3 - 1;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment(t - 1, -0.3),
                end: Alignment(t + 1, 0.3),
                colors: [base, highlight, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

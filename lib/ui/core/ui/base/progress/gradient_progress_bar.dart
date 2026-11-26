import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/app_motion.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A pill progress bar filled with the Aurora gradient. Animates between
/// values; [value] null shows a sliding indeterminate segment. [color]
/// replaces the gradient (e.g. `success` when done, `error` when failed).
class const GradientProgressBar({super.key, final double? value, final Color? color, final double height = 6})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(duration: const Duration(milliseconds: 1300));
    final indeterminate = value == null;

    useEffect(() {
      if (indeterminate && !reduceMotion) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [indeterminate, reduceMotion]);

    final fill = BoxDecoration(
      gradient: color == null ? AppGradients.aurora : null,
      color: color,
      borderRadius: AppRadius.pill,
    );

    return Semantics(
      value: indeterminate ? null : '${(value! * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(color: context.colors.surfaceRaised, borderRadius: AppRadius.pill),
        clipBehavior: .antiAlias,
        child: indeterminate
            ? AnimatedBuilder(
                animation: controller,
                builder: (context, child) => FractionallySizedBox(
                  widthFactor: 0.35,
                  // For a 0.35-wide child, x = ±2.08 puts it just outside each end.
                  alignment: Alignment(-2.08 + controller.value * 4.16, 0),
                  child: child,
                ),
                child: DecoratedBox(decoration: fill),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(end: value!.clamp(0, 1)),
                duration: reduceMotion ? .zero : AppMotion.normal,
                curve: AppMotion.standard,
                builder: (context, fraction, child) =>
                    FractionallySizedBox(alignment: .centerLeft, widthFactor: fraction, child: child),
                child: DecoratedBox(decoration: fill),
              ),
      ),
    );
  }
}

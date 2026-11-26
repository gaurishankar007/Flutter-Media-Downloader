import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A soft, blurred Aurora glow behind a screen's header. Decoration only.
class const AuroraGlow({super.key, final double height = 320}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final opacity = context.isDark ? 0.28 : 0.16;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -1.1),
              radius: 1.3,
              colors: [
                AppGradients.auroraColors[0].withValues(alpha: opacity),
                AppGradients.auroraColors[2].withValues(alpha: opacity * 0.5),
                Colors.transparent,
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ),
    );
  }
}

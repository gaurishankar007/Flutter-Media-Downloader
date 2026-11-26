import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// An icon painted with the Aurora gradient on a soft tinted square.
class const GradientIconTile({super.key, required final IconData icon, final double size = 44})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: .circular(size * 0.32),
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [
            for (final color in AppGradients.auroraColors) color.withValues(alpha: context.isDark ? 0.22 : 0.14),
          ],
        ),
        border: .all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: ShaderMask(
        shaderCallback: AppGradients.aurora.createShader,
        child: Icon(icon, size: size * 0.5, color: Colors.white, fill: 1),
      ),
    );
  }
}

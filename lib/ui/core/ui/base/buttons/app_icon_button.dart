import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A 40px circular icon button on a raised surface. [label] is the tooltip
/// and the screen-reader label, so it's required.
class const AppIconButton({
  super.key,
  required final IconData icon,
  required final String label,
  final VoidCallback? onPressed,
  final bool destructive = false,
  final double size = 40,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = switch ((onPressed, destructive)) {
      (null, _) => colors.textMuted,
      (_, true) => colors.error,
      _ => colors.textPrimary,
    };
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        // A 48px touch target around the 40px circle: taps on the ring around
        // it count too (the circle's InkWell wins inside it, with its ripple).
        child: GestureDetector(
          behavior: .opaque,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size < 48 ? 48 : size,
            child: Center(
              child: Material(
                color: destructive ? colors.error.withValues(alpha: 0.12) : colors.surfaceRaised,
                shape: const CircleBorder(),
                clipBehavior: .antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox.square(
                    dimension: size,
                    child: Icon(icon, size: size * 0.5, color: foreground),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// The one primary action on a screen, filled with the Aurora gradient.
/// Disabled when [onPressed] is null.
class const GradientButton({
  super.key,
  required final String label,
  final IconData? icon,
  final VoidCallback? onPressed,
  final bool compact = false,
  final bool expand = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final foreground = enabled ? colors.onPrimary : colors.textMuted;
    final height = compact ? 40.0 : 52.0;

    final text = Text(
      label,
      maxLines: 1,
      overflow: .ellipsis,
      style: context.text.bodyStrong.copyWith(color: foreground),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        height: height,
        decoration: BoxDecoration(
          gradient: enabled ? AppGradients.aurora : null,
          color: enabled ? null : colors.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          boxShadow: enabled
              ? [BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Material(
          type: .transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.mdAll,
            child: Padding(
              padding: .symmetric(horizontal: compact ? AppSpacing.lg : AppSpacing.xl),
              child: Row(
                mainAxisSize: expand ? .max : .min,
                mainAxisAlignment: .center,
                spacing: AppSpacing.sm,
                children: [
                  if (icon != null) Icon(icon, size: compact ? 18 : 20, color: foreground),
                  // Only a full-width button has bounded room to shrink its label into.
                  if (expand) Flexible(child: text) else text,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// Tertiary action: text only, accent colour (or `error` when [destructive]).
class const GhostButton({
  super.key,
  required final String label,
  final IconData? icon,
  final VoidCallback? onPressed,
  final bool destructive = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = switch ((onPressed, destructive)) {
      (null, _) => colors.textMuted,
      (_, true) => colors.error,
      _ => colors.primaryText,
    };
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.mdAll,
      child: Container(
        height: 44,
        padding: const .symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisSize: .min,
          spacing: AppSpacing.xs + 2,
          children: [
            if (icon != null) Icon(icon, size: 18, color: foreground),
            Text(label, maxLines: 1, style: context.text.bodyStrong.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

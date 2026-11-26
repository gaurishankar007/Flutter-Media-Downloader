import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// Secondary action: raised surface with accent text, or an error tint when
/// [destructive] (the confirm button of a delete dialog).
class const TonalButton({
  super.key,
  required final String label,
  final IconData? icon,
  final VoidCallback? onPressed,
  final bool destructive = false,
  final bool expand = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = switch ((onPressed, destructive)) {
      (null, _) => colors.textMuted,
      (_, true) => colors.error,
      _ => colors.primaryText,
    };
    final text = Text(
      label,
      maxLines: 1,
      overflow: .ellipsis,
      style: context.text.bodyStrong.copyWith(color: foreground),
    );
    return Material(
      color: destructive && onPressed != null ? colors.error.withValues(alpha: 0.14) : colors.surfaceRaised,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mdAll,
        child: Container(
          height: 44,
          padding: const .symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisSize: expand ? .max : .min,
            mainAxisAlignment: .center,
            spacing: AppSpacing.sm,
            children: [
              if (icon != null) Icon(icon, size: 18, color: foreground),
              // Only a full-width button has bounded room to shrink its label into.
              if (expand) Flexible(child: text) else text,
            ],
          ),
        ),
      ),
    );
  }
}

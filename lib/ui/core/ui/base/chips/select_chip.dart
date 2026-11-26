import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/app_motion.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A selectable pill (filters, quality, format). Selected uses the Aurora gradient.
class const SelectChip({
  super.key,
  required final String label,
  required final bool selected,
  required final VoidCallback onSelected,
  final IconData? icon,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimary : colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.aurora : null,
          color: selected ? null : colors.surfaceRaised,
          borderRadius: AppRadius.pill,
          border: .all(color: selected ? Colors.transparent : colors.outline),
        ),
        child: Material(
          type: .transparency,
          child: InkWell(
            onTap: onSelected,
            borderRadius: AppRadius.pill,
            // At least 44 high: a comfortable tap target.
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const .symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                mainAxisSize: .min,
                spacing: AppSpacing.xs + 2,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: foreground, fill: selected ? 1 : 0),
                  Text(label, maxLines: 1, style: context.text.label.copyWith(color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

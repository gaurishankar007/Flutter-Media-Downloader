import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// A row with a title, optional subtitle and icon, and a switch. The whole
/// row toggles.
class const AppSwitchTile({
  super.key,
  required final String title,
  required final bool value,
  required final ValueChanged<bool>? onChanged,
  final String? subtitle,
  final IconData? icon,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const .symmetric(vertical: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.md + 2,
            children: [
              if (icon != null) GradientIconTile(icon: icon!, size: 38),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text(title, style: context.text.bodyStrong),
                    if (subtitle != null)
                      Text(subtitle!, style: context.text.label.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

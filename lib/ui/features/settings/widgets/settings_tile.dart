import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// One setting: icon, title, optional subtitle and trailing widget, or a
/// control laid out [below] the title.
class const SettingsTile({
  super.key,
  required final IconData icon,
  required final String title,
  final String? subtitle,
  final Widget? trailing,
  final Widget? below,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const .symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: .start,
          spacing: AppSpacing.md,
          children: [
            Row(
              spacing: AppSpacing.md + 2,
              children: [
                GradientIconTile(icon: icon, size: 38),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 2,
                    children: [
                      Text(title, style: context.text.bodyStrong),
                      if (subtitle != null)
                        Text(subtitle!, style: context.text.label.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
                ?trailing,
                if (onTap != null && trailing == null) Icon(Symbols.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
            if (below != null) Padding(padding: const .only(left: 52), child: below),
          ],
        ),
      ),
    );
  }
}

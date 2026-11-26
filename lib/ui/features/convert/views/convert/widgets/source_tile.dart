import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// One place to pick the input from. Null [onTap] disables it (while a file is read).
class const SourceTile({
  super.key,
  required final IconData icon,
  required final String title,
  required final String subtitle,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: AppCard(
        onTap: onTap,
        child: Row(
          spacing: AppSpacing.lg,
          children: [
            GradientIconTile(icon: icon, size: 48),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 2,
                children: [
                  Text(title, style: context.text.bodyStrong),
                  Text(subtitle, style: context.text.label.copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}

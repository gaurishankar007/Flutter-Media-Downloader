import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// Icon, title, body and an optional action, centred.
class const EmptyState({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  final Widget? action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: .min,
        spacing: AppSpacing.md,
        children: [
          GradientIconTile(icon: icon, size: 64),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: context.text.headline, textAlign: .center),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              body,
              style: context.text.body.copyWith(color: context.colors.textSecondary),
              textAlign: .center,
            ),
          ),
          if (action != null)
            Padding(
              padding: const .only(top: AppSpacing.sm),
              child: action,
            ),
        ],
      ),
    );
  }
}

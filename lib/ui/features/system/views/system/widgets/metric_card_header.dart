import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// Icon, name and description at the top of a System page card, with the
/// live value on the right.
class const MetricCardHeader({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  final String? value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.md,
      children: [
        GradientIconTile(icon: icon, size: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: AppSpacing.xs / 2,
            children: [
              Text(title, style: context.text.bodyStrong),
              Text(body, style: context.text.caption.copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
        if (value != null)
          Text(value!, style: context.text.headline.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// "↓ Download        3.2 MB/s" on the System page's network card. [color]
/// matches the series' line in the sparkline.
class const NetworkSpeedRow({
  super.key,
  required final IconData icon,
  required final Color color,
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: 18, color: color),
        Expanded(
          child: Text(label, style: context.text.label.copyWith(color: context.colors.textSecondary)),
        ),
        Text(value, style: context.text.bodyStrong.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// "↓ Download        3.2 MB/s": a label and its value on a System page
/// card. [icon] takes [color] (on the network card, the series' line colour
/// in the sparkline).
class const MetricValueRow({
  super.key,
  required final String label,
  required final String value,
  final IconData? icon,
  final Color? color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: [
        if (icon case final icon?) Icon(icon, size: 18, color: color),
        Text(label, style: context.text.label.copyWith(color: context.colors.textSecondary)),
        // Long values (a chip name, a core layout) wrap instead of overflowing.
        Expanded(
          child: Text(
            value,
            textAlign: .end,
            style: context.text.bodyStrong.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
  }
}

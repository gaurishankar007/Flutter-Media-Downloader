import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_card_header.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_value_row.dart';

/// Storage or battery on the System page: value, a bar and label/value rows,
/// no sparkline (these change slowly). [barColor] replaces the gradient
/// (e.g. `warning` for a low battery).
class const BarMetricCard({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  required final String value,
  required final double? fraction,
  required final List<(String, String)> rows,
  final Color? barColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.md,
        children: [
          MetricCardHeader(icon: icon, title: title, body: body, value: value),
          GradientProgressBar(value: fraction, color: barColor),
          for (final (label, value) in rows) MetricValueRow(label: label, value: value),
        ],
      ),
    );
  }
}

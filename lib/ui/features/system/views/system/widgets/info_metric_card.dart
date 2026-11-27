import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_card_header.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_value_row.dart';

/// CPU or GPU on a system that keeps its live load private: hardware facts only.
class const InfoMetricCard({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  required final List<(String, String)> rows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.md,
        children: [
          MetricCardHeader(icon: icon, title: title, body: body),
          for (final (label, value) in rows) MetricValueRow(label: label, value: value),
        ],
      ),
    );
  }
}

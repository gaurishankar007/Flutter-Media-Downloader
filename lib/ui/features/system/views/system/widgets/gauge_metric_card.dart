import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_card_header.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_value_row.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/sparkline.dart';

/// RAM, CPU or GPU on the System page: value, gradient bar and the last
/// minute as a sparkline. [history] is 0–1, oldest first. Hardware [rows] and
/// a [footer] (the RAM speed test) go below.
class const GaugeMetricCard({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  required final String value,
  required final double? fraction,
  required final List<double> history,
  final String? detail,
  final List<(String, String)> rows = const [],
  final Widget? footer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted = context.text.caption.copyWith(color: context.colors.textMuted);
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.md,
        children: [
          MetricCardHeader(icon: icon, title: title, body: body, value: value),
          GradientProgressBar(value: fraction),
          if (detail != null) Text(detail!, style: context.text.numeric.copyWith(color: context.colors.textSecondary)),
          Sparkline(values: history, max: 1),
          Text(SystemMessages.lastMinute, style: muted),
          for (final (label, value) in rows) MetricValueRow(label: label, value: value),
          ?footer,
        ],
      ),
    );
  }
}

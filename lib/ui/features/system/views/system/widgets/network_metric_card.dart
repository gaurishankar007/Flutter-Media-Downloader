import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_card_header.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/network_speed_row.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/sparkline.dart';

/// Whole-device download and upload speed with both as sparklines
/// (bytes per second, oldest first; scaled to the busiest second shown).
class const NetworkMetricCard({
  super.key,
  required final IconData icon,
  required final String title,
  required final String body,
  required final String download,
  required final String upload,
  required final List<double> downloadHistory,
  required final List<double> uploadHistory,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.md,
        children: [
          MetricCardHeader(icon: icon, title: title, body: body),
          NetworkSpeedRow(
            icon: Symbols.arrow_downward_rounded,
            color: colors.primaryText,
            label: SystemMessages.download,
            value: download,
          ),
          NetworkSpeedRow(
            icon: Symbols.arrow_upward_rounded,
            color: colors.secondary,
            label: SystemMessages.upload,
            value: upload,
          ),
          Sparkline(values: downloadHistory, secondary: uploadHistory),
          Text(SystemMessages.lastMinute, style: context.text.caption.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}

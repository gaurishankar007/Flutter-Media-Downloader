import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/metric_value_row.dart';

/// The speed test at the bottom of the RAM and Storage cards: the last
/// [results] (or what the test does, before it ran) and a button.
/// [onPressed] is null while any test runs.
class const SpeedTestSection({
  super.key,
  required final String note,
  required final List<(String, String)> results,
  required final bool running,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = switch ((running, results.isEmpty)) {
      (true, _) => SystemMessages.testingSpeed,
      (false, true) => SystemMessages.testSpeed,
      (false, false) => SystemMessages.testSpeedAgain,
    };
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        for (final (label, value) in results) MetricValueRow(label: label, value: value),
        if (results.isEmpty) Text(note, style: context.text.caption.copyWith(color: context.colors.textMuted)),
        TonalButton(label: label, icon: Symbols.speed_rounded, expand: true, onPressed: onPressed),
      ],
    );
  }
}

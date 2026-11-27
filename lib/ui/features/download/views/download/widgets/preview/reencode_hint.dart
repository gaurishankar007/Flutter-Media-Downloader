import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// Warns that the chosen quality needs a slow on-phone conversion.
class const ReencodeHint({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.12), borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm,
        children: [
          Icon(Symbols.hourglass_rounded, size: 18, color: colors.warning),
          Expanded(child: Text(DownloadMessages.reencodeHint, style: context.text.label)),
        ],
      ),
    );
  }
}

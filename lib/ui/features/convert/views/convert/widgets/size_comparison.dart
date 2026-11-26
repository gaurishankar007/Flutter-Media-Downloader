import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/convert/views/convert/widgets/size_column.dart';

/// Before → after sizes with the change as a badge ("−62%" in `success`).
class const SizeComparison({super.key, required final int beforeBytes, required final int afterBytes})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = beforeBytes == 0 ? 0 : ((afterBytes - beforeBytes) * 100 / beforeBytes).round();
    final smaller = change < 0;
    final badgeColor = smaller ? colors.success : colors.textSecondary;
    return Row(
      spacing: AppSpacing.md,
      children: [
        SizeColumn(label: ConvertMessages.before, bytes: beforeBytes),
        Icon(Symbols.arrow_forward_rounded, color: colors.textMuted),
        SizeColumn(label: ConvertMessages.after, bytes: afterBytes),
        const Spacer(),
        if (change != 0)
          Container(
            padding: const .symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.14), borderRadius: AppRadius.pill),
            child: Text(
              smaller ? ConvertMessages.smaller(-change) : ConvertMessages.larger(change),
              style: context.text.bodyStrong.copyWith(color: badgeColor),
            ),
          ),
      ],
    );
  }
}

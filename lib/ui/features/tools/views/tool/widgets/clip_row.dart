import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';

/// One trim clip: its number and times. Tap selects it for editing.
class const ClipRow({
  super.key,
  required final int number,
  required final VideoClip clip,
  required final bool selected,
  required final VoidCallback onSelect,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const .symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      onTap: onSelect,
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(
            selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
            color: selected ? colors.primary : colors.textMuted,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                Text(ToolsMessages.clip(number), style: context.text.bodyStrong),
                Text(
                  ToolsMessages.range(
                    FormatUtils.clipTime(clip.start),
                    FormatUtils.clipTime(clip.end),
                    ToolsMessages.seconds(clip.length.toStringAsFixed(1)),
                  ),
                  style: context.text.numeric.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          AppIconButton(icon: Symbols.delete_rounded, label: ToolsMessages.deleteClip, onPressed: onDelete),
        ],
      ),
    );
  }
}

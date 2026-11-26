import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/audio_quality.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';

/// MP3 320 / 192 / 128 kbps.
class const AudioQualityChips({
  super.key,
  required final AudioQuality selected,
  required final ValueChanged<AudioQuality> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.sm,
      children: [
        Text(DownloadMessages.quality, style: context.text.label.copyWith(color: context.colors.textSecondary)),
        ChipRow(
          wrap: true,
          children: [
            for (final quality in AudioQuality.values)
              SelectChip(
                label: 'MP3 ${DownloadMessages.kbps(quality.kbps)}',
                selected: quality == selected,
                onSelected: () => onSelected(quality),
              ),
          ],
        ),
      ],
    );
  }
}

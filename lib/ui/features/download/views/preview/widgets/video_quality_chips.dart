import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/video_option.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';

/// Best, 4K, 1080p… each with its estimated size.
class const VideoQualityChips({
  super.key,
  required final List<VideoOption> options,
  required final int selectedIndex,
  required final ValueChanged<int> onSelected,
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
            for (final (index, option) in options.indexed)
              SelectChip(
                label: [
                  if (option.height == null)
                    DownloadMessages.best
                  else
                    DownloadMessages.resolution(option.resolution ?? option.height!),
                  if (option.sizeBytes case final size?) FormatUtils.bytes(size),
                ].join(' · '),
                selected: index == selectedIndex,
                onSelected: () => onSelected(index),
              ),
          ],
        ),
      ],
    );
  }
}

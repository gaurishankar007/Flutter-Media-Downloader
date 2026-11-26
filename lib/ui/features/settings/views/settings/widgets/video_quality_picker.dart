import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/video_quality.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';

/// Best / 4K / 1440p / 1080p / 720p / 480p.
class const VideoQualityPicker({
  super.key,
  required final VideoQuality selected,
  required final ValueChanged<VideoQuality> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final quality in VideoQuality.values)
          SelectChip(
            label: switch (quality.resolution) {
              final resolution? => SettingsMessages.resolution(resolution),
              null => SettingsMessages.best,
            },
            selected: quality == selected,
            onSelected: () => onSelected(quality),
          ),
      ],
    );
  }
}

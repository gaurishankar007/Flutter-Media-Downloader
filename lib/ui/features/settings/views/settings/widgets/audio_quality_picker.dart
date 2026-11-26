import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/audio_quality.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';

/// 320 / 192 / 128 kbps.
class const AudioQualityPicker({
  super.key,
  required final AudioQuality selected,
  required final ValueChanged<AudioQuality> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final quality in AudioQuality.values)
          SelectChip(
            label: SettingsMessages.kbps(quality.kbps),
            selected: quality == selected,
            onSelected: () => onSelected(quality),
          ),
      ],
    );
  }
}

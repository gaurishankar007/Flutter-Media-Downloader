import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/domain/models/storage_usage.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// Videos / Audio / Photos sizes, one row each.
class const StorageBreakdown({super.key, required final StorageUsage usage}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labelStyle = context.text.label.copyWith(color: context.colors.textSecondary);
    final rows = [
      (SettingsMessages.storageVideos, usage.videoBytes),
      (SettingsMessages.storageAudio, usage.audioBytes),
      (SettingsMessages.storagePhotos, usage.photoBytes),
    ];
    return Column(
      spacing: AppSpacing.xs,
      children: [
        for (final (label, bytes) in rows)
          Row(
            children: [
              Expanded(child: Text(label, style: labelStyle)),
              Text(bytes == 0 ? SettingsMessages.storageEmpty : FormatUtils.bytes(bytes), style: context.text.numeric),
            ],
          ),
      ],
    );
  }
}

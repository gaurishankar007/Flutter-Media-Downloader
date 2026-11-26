import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';

/// The picked file: thumbnail, name and what it is, with Change.
class const SourcePreview({super.key, required final LocalMediaInfo source, final VoidCallback? onChange})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final seconds = source.durationSeconds;
    final details = [
      source.format.toUpperCase(),
      FormatUtils.bytes(source.sizeBytes),
      if (source.width case final width?) '$width×${source.height}',
      if (seconds != null && seconds > 0) FormatUtils.duration(seconds.round()),
    ].join(' · ');
    return AppCard(
      child: Row(
        spacing: AppSpacing.lg,
        children: [
          SizedBox(
            width: 88,
            child: MediaThumbnail(
              kind: source.kind,
              image: source.thumbnailPath == null ? null : LocalMedia.image(source.thumbnailPath!),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                Text(source.title, style: context.text.bodyStrong, maxLines: 2, overflow: .ellipsis),
                Text(
                  details,
                  maxLines: 2,
                  overflow: .ellipsis,
                  style: context.text.label.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          GhostButton(label: ConvertMessages.change, onPressed: onChange),
        ],
      ),
    );
  }
}

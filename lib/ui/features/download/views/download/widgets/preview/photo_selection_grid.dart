import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/post_media.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/media/photo_grid.dart';

/// Every photo (and video) of a post, all selected at first: tap to toggle,
/// "Select all / none" above. See docs/features/download.md#preview.
class const PhotoSelectionGrid({
  super.key,
  required final List<PostMedia> media,
  required final Set<int> selected,
  required final ValueChanged<int> onToggle,
  required final VoidCallback onToggleAll,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final allSelected = selected.length == media.length;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DownloadMessages.photosSelected(selected.length, media.length),
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
            ),
            GhostButton(
              label: allSelected ? CommonMessages.selectNone : CommonMessages.selectAll,
              onPressed: onToggleAll,
            ),
          ],
        ),
        PhotoGrid(
          photos: [
            for (final item in media)
              if (item.previewUrl case final url?) NetworkImage(url) else null,
          ],
          selected: selected,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

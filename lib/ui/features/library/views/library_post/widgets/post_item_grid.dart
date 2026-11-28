import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/media_card.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/widgets/item_action_sheet.dart';

/// The post's items. Tap opens the viewer paging through the post;
/// long-press / right-click opens that item's actions.
class const PostItemGrid({super.key, required final List<LibraryEntry> members}) extends ConsumerWidget {
  static const _minCardWidth = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [for (final entry in members) entry.id];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minCardWidth).floor().clamp(2, 6);
        final cardWidth = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: .zero,
          itemCount: members.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: MediaCard.heightFor(context, cardWidth),
          ),
          itemBuilder: (context, index) {
            final entry = members[index];
            final item = entry.item;
            return MediaCard(
              key: ValueKey(entry.id),
              title: item.title,
              kind: item.kind,
              image: entry.thumbnailPath == null ? null : LocalMedia.image(entry.thumbnailPath!),
              duration: item.durationMs == null ? null : FormatUtils.duration(item.durationMs! ~/ 1000),
              metadata: [FormatUtils.bytes(item.sizeBytes), item.format.toUpperCase()].join(' · '),
              saved: item.isSaved,
              heroTag: 'library-${entry.id}',
              onTap: () => context.router.push(MediaViewerRoute(initialId: entry.id, ids: ids)),
              onMore: () => showItemActionSheet(context, ref, entry),
            );
          },
        );
      },
    );
  }
}

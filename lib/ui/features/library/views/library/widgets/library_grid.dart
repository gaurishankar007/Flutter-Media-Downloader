import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/media_card.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_tool/ui/features/library/widgets/item_action_sheet.dart';

/// The Library's cards. Tap opens the viewer, or a grouped post's page (or
/// toggles selection in multi-select); long-press / right-click opens the
/// item's actions.
class const LibraryGrid({super.key, required final List<LibraryEntry> entries}) extends ConsumerWidget {
  static const _minCardWidth = 168.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(libraryProvider.select((state) => state.selecting));
    final selectedIds = ref.watch(libraryProvider.select((state) => state.selectedIds));
    final notifier = ref.read(libraryProvider.notifier);
    // The viewer swipes through single items; posts open their own page.
    final ids = [
      for (final entry in entries)
        if (!entry.isGroup) entry.id,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minCardWidth).floor().clamp(2, 5);
        final cardWidth = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: .zero,
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: MediaCard.heightFor(context, cardWidth),
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final item = entry.item;
            return MediaCard(
              key: ValueKey(entry.id),
              title: item.title,
              kind: item.kind,
              site: item.site,
              image: entry.thumbnailPath == null ? null : LocalMedia.image(entry.thumbnailPath!),
              duration: item.durationMs == null ? null : FormatUtils.duration(item.durationMs! ~/ 1000),
              metadata: [FormatUtils.bytes(item.sizeBytes), item.format.toUpperCase()].join(' · '),
              saved: item.isSaved,
              heroTag: 'library-${entry.id}',
              count: entry.isGroup ? entry.ids.length : null,
              selected: selecting ? selectedIds.containsAll(entry.ids) : null,
              // A grouped post opens its own page with every item.
              onTap: selecting
                  ? () => notifier.toggleSelectedAll(entry.ids)
                  : () => context.router.push(switch (entry.item.groupId) {
                      final groupId? when entry.isGroup => LibraryPostRoute(groupId: groupId),
                      _ => MediaViewerRoute(initialId: entry.id, ids: ids),
                    }),
              onMore: selecting
                  ? () => notifier.toggleSelectedAll(entry.ids)
                  : () => showItemActionSheet(context, ref, entry),
            );
          },
        );
      },
    );
  }
}

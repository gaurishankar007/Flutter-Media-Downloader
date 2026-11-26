import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_downloader/ui/features/library/providers/library_actions/library_actions_notifier.dart';
import 'package:media_downloader/ui/features/library/widgets/item_action_sheet.dart';

/// Multi-select: count, Select all, and Save to Photos / Share / Delete for
/// the selected items.
class const SelectionBar({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final actions = ref.read(libraryActionsProvider.notifier);
    final selected = state.selected;
    final ids = [for (final entry in selected) entry.id];
    final photoIds = [
      for (final entry in selected)
        if (entry.canSaveToPhotos) entry.id,
    ];

    Future<void> delete() async {
      if (await confirmAndDelete(context, ref, ids)) {
        notifier.stopSelecting();
      }
    }

    final count = Text(
      LibraryMessages.selected(ids.length),
      maxLines: 1,
      overflow: .ellipsis,
      style: context.text.bodyStrong,
    );
    final selectAll = GhostButton(label: CommonMessages.selectAll, onPressed: notifier.toggleSelectAll);
    final buttons = [
      AppIconButton(
        icon: Symbols.photo_library_rounded,
        label: LibraryMessages.saveToPhotos,
        onPressed: photoIds.isEmpty ? null : () => actions.saveToPhotos(photoIds),
      ),
      AppIconButton(
        icon: Symbols.ios_share_rounded,
        label: CommonMessages.share,
        onPressed: ids.isEmpty ? null : () => actions.share(ids),
      ),
      AppIconButton(
        icon: Symbols.delete_rounded,
        label: CommonMessages.delete,
        destructive: true,
        onPressed: ids.isEmpty ? null : delete,
      ),
    ];

    return AppCard(
      padding: const .symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: LayoutBuilder(
        // Narrow phones: count and Select all on top, the actions under them.
        builder: (context, constraints) => constraints.maxWidth < 360
            ? Column(
                crossAxisAlignment: .stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: count),
                      selectAll,
                    ],
                  ),
                  Row(mainAxisAlignment: .end, spacing: AppSpacing.xs, children: buttons),
                ],
              )
            : Row(
                spacing: AppSpacing.xs,
                children: [
                  Expanded(child: count),
                  selectAll,
                  ...buttons,
                ],
              ),
      ),
    );
  }
}

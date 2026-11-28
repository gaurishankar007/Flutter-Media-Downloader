import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/providers/library_actions/library_actions_notifier.dart';
import 'package:media_tool/ui/features/library/widgets/item_action_sheet.dart';

/// Save all to Photos, Share all and Delete all for the post's items.
/// Save to Files picks one destination per file, so it's per item.
class const PostActions({super.key, required final List<LibraryEntry> members}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(libraryActionsProvider.notifier);
    final ids = [for (final entry in members) entry.id];
    final photoIds = [
      for (final entry in members)
        if (entry.canSaveToPhotos) entry.id,
    ];
    final busy = ref.watch(libraryActionsProvider.select((state) => ids.any(state.busyIds.contains)));
    return ChipRow(
      wrap: true,
      children: [
        if (photoIds.isNotEmpty)
          TonalButton(
            label: LibraryMessages.saveAllToPhotos,
            icon: Symbols.photo_library_rounded,
            onPressed: busy ? null : () => actions.saveToPhotos(photoIds),
          ),
        TonalButton(
          label: LibraryMessages.shareAll,
          icon: Symbols.ios_share_rounded,
          onPressed: () => actions.share(ids),
        ),
        TonalButton(
          label: LibraryMessages.deleteAll,
          icon: Symbols.delete_rounded,
          destructive: true,
          onPressed: busy ? null : () => confirmAndDelete(context, ref, ids),
        ),
      ],
    );
  }
}

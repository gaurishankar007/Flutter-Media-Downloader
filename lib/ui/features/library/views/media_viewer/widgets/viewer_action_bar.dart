import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/sheets/app_bottom_sheet.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/providers/library_actions/library_actions_notifier.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/item_info_sheet.dart';
import 'package:media_tool/ui/features/library/widgets/item_action_sheet.dart';

/// Save to Photos, Save to Files, Share, Delete and Info for the open item.
class const ViewerActionBar({super.key, required final LibraryEntry entry}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(libraryActionsProvider.notifier);
    final busy = ref.watch(libraryActionsProvider.select((state) => state.busyIds.contains(entry.id)));

    return Row(
      mainAxisAlignment: .spaceEvenly,
      children:
          [
                if (entry.canSaveToPhotos)
                  AppIconButton(
                    icon: Symbols.photo_library_rounded,
                    label: LibraryMessages.saveToPhotos,
                    onPressed: busy ? null : () => actions.saveToPhotos([entry.id]),
                  ),
                AppIconButton(
                  icon: Symbols.folder_rounded,
                  label: LibraryMessages.saveToFiles,
                  onPressed: busy ? null : () => actions.saveToFiles(entry.id),
                ),
                AppIconButton(
                  icon: Symbols.ios_share_rounded,
                  label: CommonMessages.share,
                  onPressed: () => actions.share([entry.id]),
                ),
                AppIconButton(
                  icon: Symbols.info_rounded,
                  label: LibraryMessages.info,
                  onPressed: () => showAppBottomSheet<void>(context, child: ItemInfoSheet(entry: entry)),
                ),
                AppIconButton(
                  icon: Symbols.delete_rounded,
                  label: CommonMessages.delete,
                  destructive: true,
                  onPressed: () => confirmAndDelete(context, ref, [entry.id]),
                ),
              ]
              .map(
                (button) => Padding(
                  padding: const .symmetric(vertical: AppSpacing.sm),
                  child: button,
                ),
              )
              .toList(),
    );
  }
}

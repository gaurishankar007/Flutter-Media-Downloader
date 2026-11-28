import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/ui/base/dialog/confirm_dialog.dart';
import 'package:media_tool/ui/core/ui/base/sheets/action_sheet.dart';
import 'package:media_tool/ui/features/convert/providers/convert_source/convert_source_notifier.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/providers/library_actions/library_actions_notifier.dart';

/// The long-press / right-click actions of one Library item, or of every
/// item of a grouped post.
Future<void> showItemActionSheet(BuildContext context, WidgetRef ref, LibraryEntry entry) {
  final actions = ref.read(libraryActionsProvider.notifier);
  return showActionSheet(
    context,
    title: entry.item.title,
    actions: [
      if (entry.canSaveToPhotos)
        (
          icon: Symbols.photo_library_rounded,
          label: LibraryMessages.saveToPhotos,
          onTap: () => actions.saveToPhotos(entry.ids),
          destructive: false,
        ),
      // Save to Files picks one destination per file: open the post to save one.
      if (!entry.isGroup)
        (
          icon: Symbols.folder_rounded,
          label: LibraryMessages.saveToFiles,
          onTap: () => actions.saveToFiles(entry.id),
          destructive: false,
        ),
      (
        icon: Symbols.ios_share_rounded,
        label: CommonMessages.share,
        onTap: () => actions.share(entry.ids),
        destructive: false,
      ),
      if (!entry.isGroup && entry.item.kind != .document)
        (
          icon: Symbols.swap_horiz_rounded,
          label: ConvertMessages.title,
          onTap: () {
            ref.read(convertSourceProvider.notifier).pickFromLibrary(entry.id);
            context.router.push(const ConvertRoute());
          },
          destructive: false,
        ),
      (
        icon: Symbols.delete_rounded,
        label: CommonMessages.delete,
        onTap: () => confirmAndDelete(context, ref, entry.ids),
        destructive: true,
      ),
    ],
  );
}

/// Asks before deleting [ids] from the app. Resolves to whether they were deleted.
Future<bool> confirmAndDelete(BuildContext context, WidgetRef ref, List<String> ids) async {
  if (ids.isEmpty) {
    return false;
  }
  final actions = ref.read(libraryActionsProvider.notifier);
  final confirmed = await showConfirmDialog(
    context,
    title: LibraryMessages.deleteTitle(ids.length),
    body: LibraryMessages.deleteBody,
    confirmLabel: CommonMessages.delete,
    destructive: true,
  );
  if (confirmed) {
    await actions.delete(ids);
  }
  return confirmed;
}

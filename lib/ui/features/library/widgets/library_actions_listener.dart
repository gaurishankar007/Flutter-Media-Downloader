import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/dialog/saved_remove_prompt.dart';
import 'package:media_tool/ui/core/utils/toast_util.dart';
import 'package:media_tool/ui/features/library/providers/library_actions/library_actions_notifier.dart';

/// Shows [libraryActionsProvider]'s toasts and the "remove from app?" prompt.
/// The Library screen and the viewer both wrap their content in it; only the
/// one on the visible route reacts, so nothing shows twice.
class const LibraryActionsListener({super.key, required final Widget child}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isVisible() => context.mounted && (ModalRoute.of(context)?.isCurrent ?? true);

    ref.listen(libraryActionsProvider, (previous, next) async {
      if (!isVisible()) {
        return;
      }
      if (next.message != null && next.message != previous?.message) {
        ToastUtil.showStateMessage(context, next.message);
      }
      final prompt = next.pendingRemovePrompt;
      if (prompt == null || prompt == previous?.pendingRemovePrompt) {
        return;
      }
      final notifier = ref.read(libraryActionsProvider.notifier);
      final choice = await showSavedRemovePrompt(
        context,
        place: prompt.destination == .photos ? SavedPromptMessages.photos : SavedPromptMessages.files,
      );
      if (choice.remove) {
        await notifier.confirmRemoveAfterSave(dontAskAgain: choice.dontAskAgain);
      } else {
        await notifier.dismissRemovePrompt(dontAskAgain: choice.dontAskAgain);
      }
    });

    return child;
  }
}

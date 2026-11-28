import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/media/player_controls.dart';
import 'package:media_tool/ui/core/ui/base/states/error_state.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';

/// Cover art (or the Aurora gradient with a note), title and player controls.
class const AudioViewer({super.key, required final LibraryEntry entry, required final bool active}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() => LocalMedia.player(entry.filePath), [entry.filePath]);
    final initialized = useFuture(useMemoized(controller.initialize, [controller]));
    useEffect(() => controller.dispose, [controller]);
    useEffect(() {
      if (!active) {
        controller.pause();
      }
      return null;
    }, [active]);

    final cover = entry.thumbnailPath;
    return Padding(
      padding: const .all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: .center,
        spacing: AppSpacing.xl,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Hero(
              tag: 'library-${entry.id}',
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: AppRadius.xlAll,
                  child: cover == null
                      ? DecoratedBox(
                          decoration: const BoxDecoration(gradient: AppGradients.aurora),
                          child: Icon(Symbols.music_note_rounded, size: 96, color: context.colors.onPrimary),
                        )
                      : Image(image: LocalMedia.image(cover), fit: .cover),
                ),
              ),
            ),
          ),
          Text(entry.item.title, textAlign: .center, maxLines: 2, overflow: .ellipsis, style: context.text.headline),
          if (initialized.hasError)
            const ErrorState(message: LibraryMessages.cantPlay)
          else if (initialized.connectionState == .done)
            PlayerControls(controller: controller),
        ],
      ),
    );
  }
}

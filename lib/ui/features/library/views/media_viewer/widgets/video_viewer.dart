import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/ui/base/states/error_state.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/player_controls.dart';
import 'package:video_player/video_player.dart';

/// A local video with controls. Pauses when swiped away ([active] false).
class const VideoViewer({super.key, required final LibraryEntry entry, required final bool active}) extends HookWidget {
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

    if (initialized.hasError) {
      return const Center(child: ErrorState(message: LibraryMessages.cantPlay));
    }
    final ready = initialized.connectionState == .done && controller.value.isInitialized;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ready
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () => controller.value.isPlaying ? controller.pause() : controller.play(),
                      child: VideoPlayer(controller),
                    ),
                  )
                : MediaThumbnail(
                    kind: entry.item.kind,
                    image: entry.thumbnailPath == null ? null : LocalMedia.image(entry.thumbnailPath!),
                    heroTag: 'library-${entry.id}',
                  ),
          ),
        ),
        if (ready)
          Padding(
            padding: const .symmetric(horizontal: AppSpacing.lg),
            child: PlayerControls(controller: controller),
          ),
      ],
    );
  }
}

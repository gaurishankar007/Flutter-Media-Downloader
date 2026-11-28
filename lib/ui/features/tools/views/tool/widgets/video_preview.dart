import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/ui/base/media/player_controls.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';
import 'package:video_player/video_player.dart';

/// Trim and Video to GIF's player: the picked video with play / pause and a
/// scrubber to a tenth of a second. Until it's [ready] the still shows; when it
/// [failed] (Linux has no player) a note says to use the times instead.
class const VideoPreview({
  super.key,
  required final LocalMediaInfo source,
  required final VideoPlayerController? controller,
  required final bool ready,
  required final bool failed,
}) extends StatelessWidget {
  static const _maxHeight = 360.0;

  @override
  Widget build(BuildContext context) {
    final player = controller;
    if (failed || player == null) {
      return const OptionNote(text: ToolsMessages.noPreview);
    }
    if (!ready) {
      return MediaThumbnail(
        kind: source.kind,
        image: source.thumbnailPath == null ? null : LocalMedia.image(source.thumbnailPath!),
      );
    }
    return Column(
      spacing: AppSpacing.sm,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _maxHeight),
          child: AspectRatio(
            aspectRatio: player.value.aspectRatio,
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: GestureDetector(
                onTap: () => player.value.isPlaying ? player.pause() : player.play(),
                child: VideoPlayer(player),
              ),
            ),
          ),
        ),
        PlayerControls(controller: player, precise: true),
      ],
    );
  }
}

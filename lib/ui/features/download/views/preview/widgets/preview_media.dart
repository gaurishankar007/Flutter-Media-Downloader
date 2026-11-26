import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:video_player/video_player.dart';

/// The preview's thumbnail. With a direct stream from the probe it shows ▶
/// and plays inline; otherwise it stays a thumbnail.
/// See docs/features/download.md#preview.
class const PreviewMedia({super.key, required final MediaInfo info}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stream = info.previewStream;
    final playing = useState(false);
    final failed = useState(false);
    final controller = useMemoized(
      () => playing.value && stream != null
          ? VideoPlayerController.networkUrl(Uri.parse(stream.url), httpHeaders: stream.headers)
          : null,
      [playing.value],
    );
    final initialized = useFuture(
      useMemoized(() async {
        await controller?.initialize();
        await controller?.play();
      }, [controller]),
    );
    useEffect(() => controller?.dispose, [controller]);
    useEffect(() {
      if (initialized.hasError) {
        failed.value = true;
        playing.value = false;
      }
      return null;
    }, [initialized.hasError]);

    final duration = info.durationSeconds;
    final thumbnail = MediaThumbnail(
      kind: info.hasVideo || info.previewStream != null
          ? MediaKind.video
          : info.hasPostMedia
          ? MediaKind.photo
          : MediaKind.audio,
      image: info.thumbnailUrl == null ? null : NetworkImage(info.thumbnailUrl!),
      duration: duration == null || duration == 0 ? null : FormatUtils.duration(duration),
      borderRadius: AppRadius.lgAll,
    );

    if (controller != null && initialized.connectionState == .done && controller.value.isInitialized) {
      return ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: colors.surfaceRaised,
            child: Stack(
              fit: .expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () => controller.value.isPlaying ? controller.pause() : controller.play(),
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
                Align(
                  alignment: .bottomCenter,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(playedColor: colors.primary, backgroundColor: colors.outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm,
      children: [
        Stack(
          alignment: .center,
          children: [
            thumbnail,
            if (stream != null && !failed.value && playing.value)
              CircularProgressIndicator(color: colors.onPrimary)
            else if (stream != null && !failed.value)
              Semantics(
                button: true,
                label: DownloadMessages.playPreview,
                child: Material(
                  color: colors.scrim,
                  shape: const CircleBorder(),
                  clipBehavior: .antiAlias,
                  child: InkWell(
                    onTap: () => playing.value = true,
                    child: Padding(
                      padding: const .all(AppSpacing.md),
                      child: Icon(Symbols.play_arrow_rounded, fill: 1, size: 36, color: colors.onPrimary),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (failed.value)
          Text(DownloadMessages.previewFailed, style: context.text.caption.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}

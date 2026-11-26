import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:video_player/video_player.dart';

/// Play / pause, scrubber with times, and mute for a [VideoPlayerController].
class const PlayerControls({super.key, required final VideoPlayerController controller}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final muted = value.volume == 0;
        return Row(
          spacing: AppSpacing.sm,
          children: [
            AppIconButton(
              icon: value.isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
              label: value.isPlaying ? LibraryMessages.pause : LibraryMessages.play,
              onPressed: value.isPlaying ? controller.pause : controller.play,
            ),
            Text(FormatUtils.duration(value.position.inSeconds), style: context.text.caption),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const .symmetric(vertical: AppSpacing.md),
                colors: VideoProgressColors(
                  playedColor: colors.primary,
                  bufferedColor: colors.textMuted.withValues(alpha: 0.4),
                  backgroundColor: colors.outline,
                ),
              ),
            ),
            Text(FormatUtils.duration(value.duration.inSeconds), style: context.text.caption),
            AppIconButton(
              icon: muted ? Symbols.volume_off_rounded : Symbols.volume_up_rounded,
              label: muted ? LibraryMessages.unmute : LibraryMessages.mute,
              onPressed: () => controller.setVolume(muted ? 1 : 0),
            ),
          ],
        );
      },
    );
  }
}

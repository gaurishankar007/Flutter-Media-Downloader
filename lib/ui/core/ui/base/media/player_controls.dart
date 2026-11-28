import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:video_player/video_player.dart';

/// Play / pause, scrubber with times, and mute for a [VideoPlayerController].
/// [precise] shows the times to a tenth of a second (Trim video).
class const PlayerControls({
  super.key,
  required final VideoPlayerController controller,
  final bool precise = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    String time(Duration position) => precise
        ? FormatUtils.clipTime(position.inMilliseconds / 1000)
        : FormatUtils.duration(position.inSeconds);
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
            Text(time(value.position), style: context.text.caption),
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
            Text(time(value.duration), style: context.text.caption),
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

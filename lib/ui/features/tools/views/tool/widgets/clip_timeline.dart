import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:video_player/video_player.dart';

/// The whole video as a bar with every clip marked on it (kept clips in the
/// accent colour, removed ones in red; the selected one stronger) and the
/// player's position as a line. Tap or drag to move the player there.
class const ClipTimeline({
  super.key,
  required final List<VideoClip> clips,
  required final int selected,
  required final TrimMode mode,
  required final double duration,
  required final VideoPlayerController? controller,
}) extends StatelessWidget {
  static const _height = 40.0;
  static const _playheadWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = mode == .keep ? colors.primary : colors.error;
    final player = controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double x(double seconds) => duration <= 0 ? 0 : (seconds / duration).clamp(0, 1) * width;
        void seek(double dx) {
          if (player != null && duration > 0) {
            player.seekTo(Duration(milliseconds: ((dx / width).clamp(0, 1) * duration * 1000).round()));
          }
        }

        return GestureDetector(
          onTapDown: (details) => seek(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => seek(details.localPosition.dx),
          child: SizedBox(
            height: _height,
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: colors.surfaceRaised)),
                  for (final (index, clip) in clips.indexed)
                    Positioned(
                      left: x(clip.start),
                      width: (x(clip.end) - x(clip.start)).clamp(_playheadWidth, width),
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(color: tint.withValues(alpha: index == selected ? 0.75 : 0.35)),
                    ),
                  if (player != null)
                    ValueListenableBuilder(
                      valueListenable: player,
                      builder: (context, value, _) => Positioned(
                        left: (x(value.position.inMilliseconds / 1000) - _playheadWidth / 2).clamp(0, width),
                        width: _playheadWidth,
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(color: colors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/hooks/use_preview_player.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/clip_editor.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/clip_timeline.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/video_preview.dart';

/// Video to GIF: the part of the video, picked on a preview player, then the
/// GIF's frame rate and width.
class const VideoPartOptions({super.key}) extends HookConsumerWidget {
  static const _gifSecondsWarning = 10;
  static const _frameRates = [10, 12, 15, 20, 24];
  static const _widths = [320, 480, 640, 800];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(toolSourcesProvider(.videoToGif).select((state) => state.first));
    final provider = toolOptionsProvider(.videoToGif);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final (:controller, :ready, :failed) = usePreviewPlayer(source?.path);

    if (source == null) {
      return const SizedBox.shrink();
    }
    final player = ready ? controller : null;
    final duration = source.durationSeconds ?? 0;
    final part = VideoClip(start: state.start, end: state.end);

    double position() => (player?.value.position.inMilliseconds ?? 0) / 1000;
    void seek(double seconds) => player?.seekTo(Duration(milliseconds: (seconds * 1000).round()));

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        VideoPreview(source: source, controller: controller, ready: ready, failed: failed),
        SectionHeader(
          title: ToolsMessages.part,
          trailing: Text(
            ToolsMessages.range(
              FormatUtils.clipTime(part.start),
              FormatUtils.clipTime(part.end),
              ToolsMessages.seconds(part.length.toStringAsFixed(1)),
            ),
            style: context.text.numeric.copyWith(color: context.colors.primaryText),
          ),
        ),
        if (duration > 0) ...[
          ClipTimeline(clips: [part], selected: 0, mode: .keep, duration: duration, controller: player),
          ClipEditor(
            clip: part,
            duration: duration,
            onDragStart: player?.pause,
            onChanged: (clip) => notifier.setRange(clip.start, clip.end),
            onSeek: player == null ? null : seek,
            onStartHere: player == null ? null : () => notifier.setRangeStart(position()),
            onEndHere: player == null ? null : () => notifier.setRangeEnd(position()),
          ),
          if (player != null) const OptionNote(text: ToolsMessages.partHint),
        ],
        if (part.length > _gifSecondsWarning) const OptionNote(text: ToolsMessages.longGif, warning: true),
        ChoiceSection<int>(
          title: ToolsMessages.frameRate,
          choices: [for (final fps in _frameRates) (value: fps, label: ToolsMessages.fps(fps))],
          selected: state.fps,
          onSelected: (fps) => notifier.change((state) => state.copyWith(fps: fps)),
        ),
        ChoiceSection<int>(
          title: ToolsMessages.width,
          choices: [for (final width in _widths) (value: width, label: ToolsMessages.pixels(width))],
          selected: state.gifWidth,
          onSelected: (width) => notifier.change((state) => state.copyWith(gifWidth: width)),
        ),
      ],
    );
  }
}

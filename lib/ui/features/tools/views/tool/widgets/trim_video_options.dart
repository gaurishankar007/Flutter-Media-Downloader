import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_tool/ui/core/ui/base/form/segmented_picker.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/hooks/use_preview_player.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/clip_editor.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/clip_row.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/clip_timeline.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/video_preview.dart';

/// Trim video: keep or remove clips, picked on a preview player.
class const TrimVideoOptions({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(toolSourcesProvider(.trimVideo).select((state) => state.first));
    final provider = toolOptionsProvider(.trimVideo);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final (:controller, :ready, :failed) = usePreviewPlayer(source?.path);

    if (source == null) {
      return const SizedBox.shrink();
    }
    final player = ready ? controller : null;
    final duration = source.durationSeconds ?? 0;
    final keep = state.trimMode == .keep;
    final clips = state.clips;
    final selected = clips.isEmpty ? null : clips[state.selectedClip.clamp(0, clips.length - 1)];
    final request = switch (state.request) {
      final TrimVideoRequest request => request,
      _ => null,
    };

    double position() => (player?.value.position.inMilliseconds ?? 0) / 1000;
    void seek(double seconds) => player?.seekTo(Duration(milliseconds: (seconds * 1000).round()));
    void add() => notifier.addClip(player != null ? position() : (clips.lastOrNull?.end ?? 0));

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        SegmentedPicker<TrimMode>(
          segments: const [
            (value: .keep, label: ToolsMessages.keepClips, icon: Symbols.content_cut_rounded),
            (value: .remove, label: ToolsMessages.removeClips, icon: Symbols.delete_sweep_rounded),
          ],
          selected: state.trimMode,
          onSelected: notifier.setTrimMode,
        ),
        VideoPreview(source: source, controller: controller, ready: ready, failed: failed),
        if (duration > 0)
          ClipTimeline(
            clips: clips,
            selected: state.selectedClip,
            mode: state.trimMode,
            duration: duration,
            controller: player,
          ),
        SectionHeader(
          title: ToolsMessages.clips,
          trailing: GhostButton(label: ToolsMessages.addClip, icon: Symbols.add_rounded, onPressed: add),
        ),
        for (final (index, clip) in clips.indexed)
          ClipRow(
            number: index + 1,
            clip: clip,
            selected: index == state.selectedClip,
            onSelect: () {
              notifier.selectClip(index);
              seek(clip.start);
            },
            onDelete: () => notifier.removeClip(index),
          ),
        if (selected != null && duration > 0) ...[
          ClipEditor(
            clip: selected,
            duration: duration,
            onDragStart: player?.pause,
            onChanged: (clip) => notifier.setClip(state.selectedClip, clip.start, clip.end),
            onSeek: player == null ? null : seek,
            onStartHere: player == null ? null : () => notifier.setClipStart(state.selectedClip, position()),
            onEndHere: player == null ? null : () => notifier.setClipEnd(state.selectedClip, position()),
          ),
          if (player != null) const OptionNote(text: ToolsMessages.clipHint),
        ],
        if (request != null) ...[
          OptionNote(text: ToolsMessages.resultLength(FormatUtils.clipTime(request.keptSeconds))),
          if (request.clips.length < clips.length) const OptionNote(text: ToolsMessages.overlapNote),
        ],
        if (keep && clips.length > 1)
          ChoiceSection<bool>(
            title: ToolsMessages.output,
            choices: const [
              (value: false, label: ToolsMessages.oneVideo),
              (value: true, label: ToolsMessages.separateVideos),
            ],
            selected: state.separateClips,
            onSelected: (separate) => notifier.change((state) => state.copyWith(separateClips: separate)),
          ),
        if (request?.joins ?? false)
          const OptionNote(text: ToolsMessages.joinNote)
        else
          AppSwitchTile(
            title: ToolsMessages.exactCut,
            subtitle: ToolsMessages.exactCutBody,
            icon: Symbols.content_cut_rounded,
            value: state.exactCut,
            onChanged: (exact) => notifier.change((state) => state.copyWith(exactCut: exact)),
          ),
      ],
    );
  }
}

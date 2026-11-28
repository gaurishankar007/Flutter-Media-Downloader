import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Video to GIF and Trim: the part of the video, then the GIF's frame rate
/// and width, or Trim's frame-exact switch.
class const VideoPartOptions({super.key, required final Tool tool}) extends ConsumerWidget {
  static const _gifSecondsWarning = 10;
  static const _frameRates = [10, 12, 15, 20, 24];
  static const _widths = [320, 480, 640, 800];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(tool);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final duration = ref.watch(toolSourcesProvider(tool).select((state) => state.first?.durationSeconds)) ?? 0;
    final gif = tool == .videoToGif;
    final length = state.end - state.start;
    String time(double seconds) => FormatUtils.duration(seconds.round());

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(
          title: ToolsMessages.part,
          trailing: Text(
            ToolsMessages.range(time(state.start), time(state.end), ToolsMessages.seconds(length.toStringAsFixed(1))),
            style: context.text.numeric.copyWith(color: context.colors.primaryText),
          ),
        ),
        if (duration > 0)
          RangeSlider(
            values: RangeValues(state.start.clamp(0, duration), state.end.clamp(0, duration)),
            max: duration,
            activeColor: context.colors.primary,
            inactiveColor: context.colors.surfaceRaised,
            labels: RangeLabels(time(state.start), time(state.end)),
            onChanged: (values) => notifier.setRange(values.start, values.end),
          ),
        if (gif) ...[
          if (length > _gifSecondsWarning) const OptionNote(text: ToolsMessages.longGif, warning: true),
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
        ] else
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

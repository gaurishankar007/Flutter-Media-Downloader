import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Resize: a percentage of the original (up to 4×), shown in pixels, and the format.
class const ResizeImageOptions({super.key}) extends ConsumerWidget {
  static const _percents = [25, 50, 75, 150, 200, 300, 400];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.resizeImage);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final request = state.request;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<int>(
          title: ToolsMessages.size,
          choices: [for (final percent in _percents) (value: percent, label: ToolsMessages.percent(percent))],
          selected: state.scalePercent,
          onSelected: (percent) => notifier.change((state) => state.copyWith(scalePercent: percent)),
        ),
        if (request case final ResizeImageRequest resize) ...[
          OptionNote(text: ToolsMessages.dimensions(resize.width, resize.height)),
          if (resize.upscales) const OptionNote(text: ToolsMessages.upscaleNote),
        ],
        ChoiceSection<ConvertFormat>(
          title: ToolsMessages.imageFormat,
          choices: [
            for (final format in const [ConvertFormat.jpg, ConvertFormat.png]) (value: format, label: format.label),
          ],
          selected: state.outputFormat,
          onSelected: (format) => notifier.change((state) => state.copyWith(outputFormat: format)),
        ),
      ],
    );
  }
}

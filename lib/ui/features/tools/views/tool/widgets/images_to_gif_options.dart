import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';

/// Images to GIF: how long each image shows, and the GIF's width.
class const ImagesToGifOptions({super.key}) extends ConsumerWidget {
  static const _durations = [0.25, 0.5, 1.0, 2.0, 3.0];
  static const _widths = [320, 480, 640, 800];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.imagesToGif);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<double>(
          title: ToolsMessages.perImage,
          choices: [
            for (final seconds in _durations)
              (value: seconds, label: ToolsMessages.seconds(seconds % 1 == 0 ? '${seconds.round()}' : '$seconds')),
          ],
          selected: state.secondsPerImage,
          onSelected: (seconds) => notifier.change((state) => state.copyWith(secondsPerImage: seconds)),
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

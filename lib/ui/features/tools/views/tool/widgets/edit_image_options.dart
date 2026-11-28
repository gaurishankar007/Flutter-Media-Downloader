import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/models/crop_aspect.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/edit_preview.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Rotate & crop: a live preview, turn / flip buttons, crop shapes and the format.
class const EditImageOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.editImage);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final source = ref.watch(toolSourcesProvider(.editImage).select((state) => state.first));
    if (source == null) {
      return const SizedBox.shrink();
    }
    final crop = switch (state.request) {
      final EditImageRequest request => request.crop,
      _ => null,
    };
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        EditPreview(
          path: source.path,
          aspectRatio: (source.width ?? 1) / (source.height ?? 1),
          quarterTurns: state.quarterTurns,
          flipHorizontal: state.flipHorizontal,
          flipVertical: state.flipVertical,
          crop: crop,
        ),
        const SectionHeader(title: ToolsMessages.rotate),
        ChipRow(
          wrap: true,
          children: [
            SelectChip(
              label: ToolsMessages.rotateLeft,
              icon: Symbols.rotate_left_rounded,
              selected: false,
              onSelected: () => notifier.rotateImage(3),
            ),
            SelectChip(
              label: ToolsMessages.rotateRight,
              icon: Symbols.rotate_right_rounded,
              selected: false,
              onSelected: () => notifier.rotateImage(1),
            ),
            SelectChip(
              label: ToolsMessages.flipHorizontal,
              icon: Symbols.flip_rounded,
              selected: state.flipHorizontal,
              onSelected: () => notifier.change((state) => state.copyWith(flipHorizontal: !state.flipHorizontal)),
            ),
            SelectChip(
              label: ToolsMessages.flipVertical,
              icon: Symbols.swap_vert_rounded,
              selected: state.flipVertical,
              onSelected: () => notifier.change((state) => state.copyWith(flipVertical: !state.flipVertical)),
            ),
          ],
        ),
        ChoiceSection<CropAspect>(
          title: ToolsMessages.crop,
          choices: [for (final aspect in CropAspect.values) (value: aspect, label: aspect.label)],
          selected: state.cropAspect,
          onSelected: (aspect) => notifier.change((state) => state.copyWith(cropAspect: aspect)),
        ),
        if (state.cropAspect != .original) const OptionNote(text: ToolsMessages.cropNote),
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

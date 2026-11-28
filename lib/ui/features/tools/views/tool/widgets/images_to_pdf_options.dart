import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Images to PDF: page size, orientation and margin.
class const ImagesToPdfOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.imagesToPdf);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final fit = state.paper == .fit;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<PdfPaperSize>(
          title: ToolsMessages.pageSize,
          choices: const [
            (value: .a4, label: ToolsMessages.pageA4),
            (value: .letter, label: ToolsMessages.pageLetter),
            (value: .fit, label: ToolsMessages.pageFit),
          ],
          selected: state.paper,
          onSelected: (paper) => notifier.change((state) => state.copyWith(paper: paper)),
        ),
        // A fitted page takes the image's own shape.
        if (fit)
          const OptionNote(text: ToolsMessages.orientationFitNote)
        else
          ChoiceSection<PdfOrientation>(
            title: ToolsMessages.orientation,
            choices: const [
              (value: .auto, label: ToolsMessages.orientationAuto),
              (value: .portrait, label: ToolsMessages.orientationPortrait),
              (value: .landscape, label: ToolsMessages.orientationLandscape),
            ],
            selected: state.orientation,
            onSelected: (orientation) => notifier.change((state) => state.copyWith(orientation: orientation)),
          ),
        ChoiceSection<PdfMargin>(
          title: ToolsMessages.margin,
          choices: const [
            (value: .none, label: ToolsMessages.marginNone),
            (value: .small, label: ToolsMessages.marginSmall),
            (value: .large, label: ToolsMessages.marginLarge),
          ],
          selected: state.margin,
          onSelected: (margin) => notifier.change((state) => state.copyWith(margin: margin)),
        ),
      ],
    );
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';

/// PDF to images: JPG or PNG, and how sharp.
class const PdfToImagesOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.pdfToImages);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<ConvertFormat>(
          title: ToolsMessages.imageFormat,
          choices: [
            for (final format in const [ConvertFormat.jpg, ConvertFormat.png]) (value: format, label: format.label),
          ],
          selected: state.imageFormat,
          onSelected: (format) => notifier.change((state) => state.copyWith(imageFormat: format)),
        ),
        ChoiceSection<PdfRenderDpi>(
          title: ToolsMessages.quality,
          choices: [
            for (final dpi in PdfRenderDpi.values)
              (
                value: dpi,
                label:
                    '${switch (dpi) {
                      .screen => ToolsMessages.dpiScreen,
                      .standard => ToolsMessages.dpiStandard,
                      .print => ToolsMessages.dpiPrint,
                    }} · ${ToolsMessages.dpi(dpi.dpi)}',
              ),
          ],
          selected: state.dpi,
          onSelected: (dpi) => notifier.change((state) => state.copyWith(dpi: dpi)),
        ),
      ],
    );
  }
}

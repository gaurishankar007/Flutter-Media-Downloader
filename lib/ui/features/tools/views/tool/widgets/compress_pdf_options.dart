import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Compress PDF: how hard, and what it does to text.
class const CompressPdfOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.compressPdf);
    final level = ref.watch(provider.select((state) => state.compressLevel));
    final notifier = ref.read(provider.notifier);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<PdfCompressLevel>(
          title: ToolsMessages.compression,
          choices: const [
            (value: .light, label: ToolsMessages.compressLight),
            (value: .medium, label: ToolsMessages.compressMedium),
            (value: .strong, label: ToolsMessages.compressStrong),
          ],
          selected: level,
          onSelected: (level) => notifier.change((state) => state.copyWith(compressLevel: level)),
        ),
        const OptionNote(text: ToolsMessages.compressNote),
      ],
    );
  }
}

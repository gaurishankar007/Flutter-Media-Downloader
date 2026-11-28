import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/form/app_text_field.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Unlock PDF: the password, when the PDF needs one to open.
class const UnlockPdfOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(toolSourcesProvider(.unlockPdf).select((state) => state.first));
    final notifier = ref.read(toolOptionsProvider(.unlockPdf).notifier);
    if (source == null) {
      return const SizedBox.shrink();
    }
    if (!source.encrypted) {
      return const OptionNote(text: ToolsMessages.notLocked);
    }
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: ToolsMessages.password),
        AppTextField(
          // A new file gets an empty field.
          key: ValueKey(source.path),
          hint: ToolsMessages.passwordHint,
          icon: Symbols.key_rounded,
          obscure: true,
          onChanged: (password) => notifier.change((state) => state.copyWith(password: password)),
        ),
      ],
    );
  }
}

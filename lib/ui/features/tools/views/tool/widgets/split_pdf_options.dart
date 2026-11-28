import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/form/app_slider.dart';
import 'package:media_tool/ui/core/ui/base/form/app_text_field.dart';
import 'package:media_tool/ui/features/tools/models/split_mode.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/choice_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';

/// Split PDF: every page, every few pages, or typed ranges; and how many
/// PDFs that makes.
class const SplitPdfOptions({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.splitPdf);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final source = ref.watch(toolSourcesProvider(.splitPdf).select((state) => state.first));
    final pageCount = source?.pageCount ?? 0;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ChoiceSection<SplitMode>(
          title: ToolsMessages.splitHow,
          choices: [for (final mode in SplitMode.values) (value: mode, label: mode.label)],
          selected: state.splitMode,
          onSelected: (mode) => notifier.change((state) => state.copyWith(splitMode: mode)),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (state.splitMode) {
          .each => const SizedBox.shrink(),
          .every => AppSlider(
            label: ToolsMessages.pagesPerPart,
            valueLabel: '${state.pagesPerPart}',
            value: state.pagesPerPart.toDouble(),
            min: 1,
            max: pageCount < 2 ? 2 : pageCount.toDouble(),
            divisions: pageCount < 2 ? 1 : pageCount - 1,
            onChanged: pageCount < 2
                ? null
                : (value) => notifier.change((state) => state.copyWith(pagesPerPart: value.round())),
          ),
          .ranges => AppTextField(
            key: ValueKey(source?.path),
            initialValue: state.ranges,
            hint: ToolsMessages.rangesHint,
            icon: Symbols.format_list_numbered_rounded,
            keyboardType: .visiblePassword,
            onChanged: (ranges) => notifier.change((state) => state.copyWith(ranges: ranges)),
          ),
        },
        if (state.partCount > 0) OptionNote(text: ToolsMessages.splitParts(state.partCount)),
      ],
    );
  }
}

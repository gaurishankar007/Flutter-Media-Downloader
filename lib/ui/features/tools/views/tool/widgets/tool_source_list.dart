import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/core/ui/base/sheets/action_sheet.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/source_row.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_library_picker.dart';

/// The picked files. One file shows with Change; several can be dragged into
/// order, removed, and added to.
class const ToolSourceList({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toolSourcesProvider(tool));
    final notifier = ref.read(toolSourcesProvider(tool).notifier);
    final sources = state.sources;

    void addMore() => showActionSheet(
      context,
      title: ToolsMessages.addMore,
      actions: [
        (
          icon: Symbols.video_library_rounded,
          label: ToolsMessages.fromLibrary,
          onTap: () => pickFromToolLibrary(context, ref, tool),
          destructive: false,
        ),
        if (tool.canPickFromPhotos)
          (
            icon: Symbols.photo_library_rounded,
            label: ToolsMessages.fromPhotos,
            onTap: () => notifier.pick(.photos),
            destructive: false,
          ),
        (
          icon: Symbols.folder_rounded,
          label: ToolsMessages.fromFiles,
          onTap: () => notifier.pick(.files),
          destructive: false,
        ),
      ],
    );

    if (!tool.multiple) {
      return SourceRow(source: sources.first, onRemove: notifier.clear);
    }
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding: .zero,
          itemCount: sources.length,
          onReorderItem: notifier.reorder,
          itemBuilder: (context, index) => Padding(
            key: ValueKey(sources[index].path),
            padding: const .only(bottom: AppSpacing.sm),
            child: SourceRow(source: sources[index], index: index, onRemove: () => notifier.remove(index)),
          ),
        ),
        if (state.isReading)
          const GradientProgressBar()
        else
          TonalButton(label: ToolsMessages.addMore, icon: Symbols.add_rounded, expand: true, onPressed: addMore),
      ],
    );
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/source_tile.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_library_picker.dart';

/// From Library · From Photos (images and videos only) · From Files.
class const ToolSourceTiles({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(toolSourcesProvider(tool).notifier);
    final reading = ref.watch(toolSourcesProvider(tool).select((state) => state.isReading));
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        SourceTile(
          icon: Symbols.video_library_rounded,
          title: ToolsMessages.fromLibrary,
          subtitle: ToolsMessages.fromLibraryBody,
          onTap: reading ? null : () => pickFromToolLibrary(context, ref, tool),
        ),
        if (tool.canPickFromPhotos)
          SourceTile(
            icon: Symbols.photo_library_rounded,
            title: ToolsMessages.fromPhotos,
            subtitle: ToolsMessages.fromPhotosBody,
            onTap: reading ? null : () => notifier.pick(.photos),
          ),
        SourceTile(
          icon: Symbols.folder_rounded,
          title: ToolsMessages.fromFiles,
          subtitle: tool.filesBody,
          onTap: reading ? null : () => notifier.pick(.files),
        ),
        if (reading) ...[const GradientProgressBar(), const Text(ToolsMessages.reading, textAlign: .center)],
      ],
    );
  }
}

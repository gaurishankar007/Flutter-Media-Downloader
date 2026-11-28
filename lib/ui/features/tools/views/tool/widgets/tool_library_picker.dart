import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/sheets/app_bottom_sheet.dart';
import 'package:media_tool/ui/features/library/widgets/library_picker_sheet.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';

/// Opens the Library picker limited to what [tool] takes and adds the picks.
Future<void> pickFromToolLibrary(BuildContext context, WidgetRef ref, Tool tool) async {
  final ids = await showAppBottomSheet<List<String>>(
    context,
    child: LibraryPickerSheet(
      kinds: switch (tool.input) {
        .images || .gif => const {.photo},
        .pdf => const {.document},
        .video => const {.video},
      },
      formats: tool.input.extensions,
      multiple: tool.multiple,
      emptyText: ToolsMessages.libraryNothingFits,
    ),
  );
  if (ids != null && ids.isNotEmpty) {
    await ref.read(toolSourcesProvider(tool).notifier).pickFromLibrary(ids);
  }
}

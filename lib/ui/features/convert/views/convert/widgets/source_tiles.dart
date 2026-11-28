import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/source_tile.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/core/ui/base/sheets/app_bottom_sheet.dart';
import 'package:media_tool/ui/features/convert/providers/convert_source/convert_source_notifier.dart';
import 'package:media_tool/ui/features/library/widgets/library_picker_sheet.dart';

/// Step 1: From Library · From Photos · From Files.
class const SourceTiles({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(convertSourceProvider.notifier);
    final reading = ref.watch(convertSourceProvider.select((state) => state.isReading));

    Future<void> pickFromLibrary() async {
      final ids = await showAppBottomSheet<List<String>>(
        context,
        child: const LibraryPickerSheet(kinds: {.video, .audio, .photo}),
      );
      if (ids?.firstOrNull case final id?) {
        await notifier.pickFromLibrary(id);
      }
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        SourceTile(
          icon: Symbols.video_library_rounded,
          title: ConvertMessages.fromLibrary,
          subtitle: ConvertMessages.fromLibraryBody,
          onTap: reading ? null : pickFromLibrary,
        ),
        SourceTile(
          icon: Symbols.photo_library_rounded,
          title: ConvertMessages.fromPhotos,
          subtitle: ConvertMessages.fromPhotosBody,
          onTap: reading ? null : notifier.pickFromPhotos,
        ),
        SourceTile(
          icon: Symbols.folder_rounded,
          title: ConvertMessages.fromFiles,
          subtitle: ConvertMessages.fromFilesBody,
          onTap: reading ? null : notifier.pickFromFiles,
        ),
        if (reading) ...[const GradientProgressBar(), const Text(ConvertMessages.reading, textAlign: .center)],
      ],
    );
  }
}

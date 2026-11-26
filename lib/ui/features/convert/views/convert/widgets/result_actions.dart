import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/features/convert/providers/convert_job/convert_job_notifier.dart';

/// Photos · Files · Share in one row, then Done. Pinned at the bottom of the
/// Convert screen once the job is done.
class const ResultActions({super.key, required final VoidCallback onDone}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertJobProvider);
    final notifier = ref.read(convertJobProvider.notifier);
    final enabled = !state.busy;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Full labels and icons only where three buttons fit them.
            final roomy = constraints.maxWidth >= 520;
            final icons = constraints.maxWidth >= 360;
            return Row(
              spacing: AppSpacing.sm,
              children: [
                if (state.canSaveToPhotos)
                  Expanded(
                    child: TonalButton(
                      label: roomy ? LibraryMessages.saveToPhotos : ConvertMessages.savePhotosShort,
                      icon: icons ? Symbols.photo_library_rounded : null,
                      expand: true,
                      onPressed: enabled ? notifier.saveToPhotos : null,
                    ),
                  ),
                Expanded(
                  child: TonalButton(
                    label: roomy ? LibraryMessages.saveToFiles : ConvertMessages.saveFilesShort,
                    icon: icons ? Symbols.folder_rounded : null,
                    expand: true,
                    onPressed: enabled ? notifier.saveToFiles : null,
                  ),
                ),
                Expanded(
                  child: TonalButton(
                    label: CommonMessages.share,
                    icon: icons ? Symbols.ios_share_rounded : null,
                    expand: true,
                    onPressed: enabled ? notifier.share : null,
                  ),
                ),
              ],
            );
          },
        ),
        GradientButton(label: ConvertMessages.done, icon: Symbols.check_rounded, expand: true, onPressed: onDone),
      ],
    );
  }
}

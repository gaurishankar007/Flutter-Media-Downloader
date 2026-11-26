import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/dialog/confirm_dialog.dart';
import 'package:media_downloader/ui/core/ui/base/dialog/saved_remove_prompt.dart';
import 'package:media_downloader/ui/core/ui/base/sheets/action_sheet.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';

class const GalleryOverlaysSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void noop() {}

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: DesignGalleryMessages.overlays),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TonalButton(
              label: DesignGalleryMessages.actionSheet,
              icon: Symbols.more_horiz_rounded,
              onPressed: () => showActionSheet(
                context,
                title: DesignGalleryMessages.sampleTitle,
                actions: [
                  (
                    icon: Symbols.photo_library_rounded,
                    label: DesignGalleryMessages.secondary,
                    onTap: noop,
                    destructive: false,
                  ),
                  (
                    icon: Symbols.folder_rounded,
                    label: DesignGalleryMessages.saveToFiles,
                    onTap: noop,
                    destructive: false,
                  ),
                  (icon: Symbols.ios_share_rounded, label: CommonMessages.share, onTap: noop, destructive: false),
                  (icon: Symbols.swap_horiz_rounded, label: NavMessages.convert, onTap: noop, destructive: false),
                  (icon: Symbols.delete_rounded, label: CommonMessages.delete, onTap: noop, destructive: true),
                ],
              ),
            ),
            TonalButton(
              label: DesignGalleryMessages.confirm,
              icon: Symbols.help_rounded,
              onPressed: () => showConfirmDialog(
                context,
                title: DesignGalleryMessages.deleteTitle,
                body: DesignGalleryMessages.deleteBody,
                confirmLabel: CommonMessages.delete,
                destructive: true,
              ),
            ),
            TonalButton(
              label: DesignGalleryMessages.savedPrompt,
              icon: Symbols.check_circle_rounded,
              onPressed: () => showSavedRemovePrompt(context, place: SavedPromptMessages.photos),
            ),
          ],
        ),
      ],
    );
  }
}

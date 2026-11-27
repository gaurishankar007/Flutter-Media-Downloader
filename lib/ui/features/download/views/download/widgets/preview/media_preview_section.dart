import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/download/providers/media_preview/media_preview_notifier.dart';
import 'package:media_tool/ui/features/download/views/download/widgets/preview/media_preview_body.dart';

/// The preview on the Download screen, above the downloads: what the link is,
/// Video / Audio / Photos, quality or the photos to keep, iPhone-compatible,
/// and Download. Stays until Download or the close button, also across tabs.
class const MediaPreviewSection({super.key, required final VoidCallback onDownload}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(mediaPreviewProvider.select((state) => state.isOpen));

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: .topCenter,
      child: !isOpen
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: .stretch,
              children: [
                SectionHeader(
                  title: DownloadMessages.preview,
                  trailing: AppIconButton(
                    icon: Symbols.close_rounded,
                    label: DownloadMessages.closePreview,
                    size: 36,
                    onPressed: ref.read(mediaPreviewProvider.notifier).close,
                  ),
                ),
                AppCard(child: MediaPreviewBody(onDownload: onDownload)),
              ],
            ),
    );
  }
}

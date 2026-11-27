import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/form/link_field.dart';
import 'package:media_tool/ui/core/ui/base/layout/aurora_glow.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/core/ui/base/states/empty_state.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/download/providers/download_queue/download_queue_notifier.dart';
import 'package:media_tool/ui/features/download/providers/engine_status/engine_status_notifier.dart';
import 'package:media_tool/ui/features/download/providers/link_input/link_input_notifier.dart';
import 'package:media_tool/ui/features/download/providers/media_preview/media_preview_notifier.dart';
import 'package:media_tool/ui/features/download/views/download/widgets/download_jobs_section.dart';
import 'package:media_tool/ui/features/download/views/download/widgets/link_status_panel.dart';
import 'package:media_tool/ui/features/download/views/download/widgets/preview/media_preview_section.dart';
import 'package:media_tool/ui/features/download/views/download/widgets/supported_sites_row.dart';

/// Paste a link → preview → download. See docs/features/download.md.
@RoutePage()
class const DownloadScreen({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final notifier = ref.read(linkInputProvider.notifier);
    final linkState = ref.watch(linkInputProvider);
    final hasJobs = ref.watch(downloadQueueProvider.select((state) => state.jobs.isNotEmpty));
    final preview = ref.read(mediaPreviewProvider.notifier);
    final url = linkState.url;
    // No Preview button for the link that's already in the preview.
    final previewing = ref.watch(mediaPreviewProvider.select((state) => state.isOpen && state.url == '$url'));

    ref
      ..listenMessages(linkInputProvider, context)
      ..listenMessages(downloadQueueProvider, context)
      // Starts the engine now (after the first frame) so it's ready by Preview.
      ..listen(engineStatusProvider, (_, _) {})
      // Paste and clean-up change the text from the notifier side.
      ..listen(linkInputProvider.select((state) => state.text), (_, text) {
        if (controller.text != text) {
          controller.value = TextEditingValue(
            text: text,
            selection: .collapsed(offset: text.length),
          );
        }
      });

    void openPreview() {
      if ((url, linkState.site) case (final url?, final site?)) {
        preview.start('$url', site);
      }
    }

    void download() {
      final request = preview.buildRequest();
      if (request == null) {
        return;
      }
      ref.read(downloadQueueProvider.notifier).enqueue(request);
      preview.close();
      notifier.clear();
    }

    return ScreenScrollView(
      background: const AuroraGlow(),
      children: [
        const ScreenHeader(title: DownloadMessages.title, subtitle: DownloadMessages.subtitle, large: true),
        const SupportedSitesRow(),
        const SizedBox(height: AppSpacing.section),
        LinkField(
          controller: controller,
          site: linkState.site,
          onChanged: notifier.onChanged,
          onPaste: notifier.pasteFromClipboard,
          onClear: notifier.clear,
        ),
        LinkStatusPanel(status: linkState.linkStatus, site: linkState.site, onPreview: previewing ? null : openPreview),
        MediaPreviewSection(onDownload: download),
        if (hasJobs)
          const DownloadJobsSection()
        else ...[
          const SectionHeader(title: DownloadMessages.downloads),
          const AppCard(
            child: EmptyState(
              icon: Symbols.download_rounded,
              title: DownloadMessages.emptyTitle,
              body: DownloadMessages.emptyBody,
            ),
          ),
        ],
      ],
    );
  }
}

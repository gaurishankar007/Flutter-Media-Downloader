import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/core/ui/base/states/empty_state.dart';
import 'package:media_downloader/ui/core/ui/base/states/error_state.dart';
import 'package:media_downloader/ui/core/ui/base/states/shimmer_box.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';

class const GalleryStatesSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: DesignGalleryMessages.states),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.md,
          children: [
            // Loading placeholder shaped like a job card.
            const AppCard(
              padding: .all(AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  ShimmerBox(width: 104, height: 58, borderRadius: AppRadius.mdAll),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: AppSpacing.sm,
                      children: [
                        ShimmerBox(height: 14),
                        FractionallySizedBox(widthFactor: 0.6, child: ShimmerBox(height: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppCard(
              child: EmptyState(
                icon: Symbols.download_rounded,
                title: DownloadMessages.emptyTitle,
                body: DownloadMessages.emptyBody,
              ),
            ),
            AppCard(
              child: ErrorState(message: DesignGalleryMessages.sampleError, onRetry: () {}),
            ),
          ],
        ),
      ],
    );
  }
}

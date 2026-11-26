import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/states/shimmer_box.dart';

/// Placeholder shaped like the preview while the engine starts or the link
/// is looked up.
class const PreviewLoading({super.key, required final bool waitingForEngine}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        const AspectRatio(
          aspectRatio: 16 / 9,
          child: ShimmerBox(borderRadius: AppRadius.lgAll),
        ),
        const ShimmerBox(height: 18),
        const FractionallySizedBox(alignment: .centerLeft, widthFactor: 0.5, child: ShimmerBox(height: 14)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.primaryText),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    waitingForEngine ? DownloadMessages.preparingEngine : DownloadMessages.loadingPreview,
                    style: context.text.bodyStrong,
                  ),
                  if (waitingForEngine)
                    Text(
                      DownloadMessages.preparingEngineBody,
                      style: context.text.label.copyWith(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_downloader/ui/core/utils/local_media.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_job/convert_job_notifier.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/size_comparison.dart';

/// Step 3: preview of the new file and before → after sizes. Its actions
/// (ResultActions) are pinned at the bottom of the screen.
class const ConvertResultSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertJobProvider);
    final request = state.request;
    final result = state.result;
    if (request == null) {
      return const SizedBox.shrink();
    }
    final thumbnail = state.resultThumbnailPath;
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.lg,
        children: [
          MediaThumbnail(kind: request.format.kind, image: thumbnail == null ? null : LocalMedia.image(thumbnail)),
          Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(
                result?.title ?? request.source.title,
                style: context.text.bodyStrong,
                maxLines: 2,
                overflow: .ellipsis,
              ),
              Text(
                ConvertMessages.resultBody,
                maxLines: 2,
                overflow: .ellipsis,
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
          SizeComparison(
            beforeBytes: request.source.sizeBytes,
            afterBytes: result?.sizeBytes ?? state.progress?.sizeBytes ?? 0,
          ),
        ],
      ),
    );
  }
}

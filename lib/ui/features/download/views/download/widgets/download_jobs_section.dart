import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';
import 'package:media_downloader/ui/features/download/providers/download_queue/download_queue_notifier.dart';
import 'package:media_downloader/ui/features/download/views/download/widgets/download_job_card.dart';

/// "In progress" and "Finished" job lists, newest first.
class const DownloadJobsSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(downloadQueueProvider);
    final inProgress = queue.inProgress;
    final finished = queue.finished;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (inProgress.isNotEmpty) ...[
          const SectionHeader(title: DownloadMessages.inProgress),
          for (final job in inProgress)
            Padding(
              padding: const .only(bottom: AppSpacing.md),
              child: DownloadJobCard(key: ValueKey(job.id), job: job),
            ),
        ],
        if (finished.isNotEmpty) ...[
          SectionHeader(
            title: DownloadMessages.finished,
            trailing: GhostButton(
              label: DownloadMessages.clearFinished,
              onPressed: ref.read(downloadQueueProvider.notifier).clearFinished,
            ),
          ),
          for (final job in finished)
            Padding(
              padding: const .only(bottom: AppSpacing.md),
              child: DownloadJobCard(key: ValueKey(job.id), job: job),
            ),
        ],
      ],
    );
  }
}

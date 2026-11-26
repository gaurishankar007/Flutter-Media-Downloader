import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/domain/models/download_job.dart';
import 'package:media_downloader/domain/models/job_progress.dart';
import 'package:media_downloader/routing/routes.gr.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/cards/job_card.dart';
import 'package:media_downloader/ui/core/ui/base/dialog/confirm_dialog.dart';
import 'package:media_downloader/ui/features/download/providers/download_queue/download_queue_notifier.dart';
import 'package:media_downloader/ui/features/download/providers/engine_status/engine_status_notifier.dart';

/// A [JobCard] for one download with the actions its stage allows:
/// Cancel while running, Share / Remove when done, Retry / Dismiss after a
/// failure or cancel.
class const DownloadJobCard({super.key, required final DownloadJob job}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(downloadQueueProvider.notifier);
    final request = job.request;
    final progress = job.progress;

    Future<void> confirmRemove() async {
      final confirmed = await showConfirmDialog(
        context,
        title: DownloadMessages.removeTitle,
        body: DownloadMessages.removeBody,
        confirmLabel: CommonMessages.remove,
        destructive: true,
      );
      if (confirmed) {
        await notifier.remove(job.id);
      }
    }

    final quality = switch (request.kind) {
      _ when request.slideshowVideo => 'MP4',
      _ when request.isPost =>
        request.media.every((media) => media.kind == .photo)
            ? DownloadMessages.photoCount(request.media.length)
            : DownloadMessages.itemCount(request.media.length),
      .audio => 'MP3 ${DownloadMessages.kbps(request.audioQuality.kbps)}',
      _ => [if (request.resolution case final resolution?) DownloadMessages.resolution(resolution), 'MP4'].join(' '),
    };

    final (status, detail) = switch (job.stage) {
      .queued => (null, DownloadMessages.waiting),
      .downloading => (
        [
          if (progress.fraction case final fraction?) DownloadMessages.percent((fraction * 100).round()),
          if (progress.speedBytesPerSecond case final speed? when speed > 0) FormatUtils.speed(speed),
        ].join(' · '),
        [quality, if (progress.etaSeconds case final eta? when eta > 0) FormatUtils.eta(eta)].join(' · '),
      ),
      .processing => (
        progress.fraction == null ? null : DownloadMessages.percent((progress.fraction! * 100).round()),
        _stepLabel(progress.step),
      ),
      .saving => (null, DownloadMessages.saving),
      .done => (null, [quality, if (progress.sizeBytes case final size?) FormatUtils.bytes(size)].join(' · ')),
      .failed => (null, progress.errorMessage ?? CommonMessages.genericError),
      .cancelled => (null, quality),
    };

    final itemIds = progress.libraryItemIds;
    final openInLibrary = job.stage == .done && itemIds.isNotEmpty
        ? () => context.router.push(MediaViewerRoute(initialId: itemIds.first, ids: itemIds))
        : null;

    return JobCard(
      onTap: openInLibrary,
      title: request.title,
      kind: request.kind,
      site: request.site,
      stage: job.stage,
      image: request.thumbnailUrl == null ? null : NetworkImage(request.thumbnailUrl!),
      progress: progress.fraction,
      status: status == null || status.isEmpty ? null : status,
      detail: detail,
      actions: switch (job.stage) {
        .queued || .downloading || .processing => [
          AppIconButton(
            icon: Symbols.close_rounded,
            label: JobStageMessages.cancelJob,
            onPressed: () => notifier.cancel(job.id),
          ),
        ],
        .saving => const [],
        .done => [
          TonalButton(
            label: CommonMessages.share,
            icon: Symbols.ios_share_rounded,
            onPressed: () => notifier.share(job.id),
          ),
          AppIconButton(
            icon: Symbols.delete_rounded,
            label: CommonMessages.remove,
            destructive: true,
            onPressed: confirmRemove,
          ),
        ],
        .failed || .cancelled => [
          GhostButton(label: DownloadMessages.dismiss, onPressed: () => notifier.dismiss(job.id)),
          // The failure's own fix, when it has one.
          if (job.stage == .failed)
            ?switch (progress.errorMessage) {
              EngineMessages.extractorBroken => GhostButton(
                label: EngineMessages.updateEngine,
                onPressed: ref.read(engineStatusProvider.notifier).update,
              ),
              EngineMessages.needsLogin || EngineMessages.botCheck => GhostButton(
                label: EngineMessages.importCookies,
                onPressed: () => context.router.push(const CookiesRoute()),
              ),
              _ => null,
            },
          TonalButton(
            label: CommonMessages.retry,
            icon: Symbols.refresh_rounded,
            onPressed: () => notifier.retry(job.id),
          ),
        ],
      },
    );
  }

  static String _stepLabel(ProcessingStep? step) => switch (step) {
    .merging => DownloadMessages.merging,
    .extractingAudio => DownloadMessages.extractingAudio,
    .convertingForIphone => DownloadMessages.convertingForIphone,
    .convertingPhotos => DownloadMessages.convertingPhotos,
    .makingSlideshow => DownloadMessages.makingSlideshow,
    .finishing || null => DownloadMessages.finishing,
  };
}

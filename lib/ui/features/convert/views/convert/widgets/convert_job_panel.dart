import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/job_card.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/convert/providers/convert_job/convert_job_notifier.dart';

/// The running conversion as a [JobCard] with Cancel, or its failure with Try again.
class const ConvertJobPanel({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertJobProvider);
    final notifier = ref.read(convertJobProvider.notifier);
    final request = state.request;
    final progress = state.progress;
    final stage = state.stage;
    if (request == null || progress == null || stage == null) {
      return const SizedBox.shrink();
    }
    final source = request.source;
    final action = request.isCompress ? ConvertMessages.compressing : ConvertMessages.converting;
    final target = '${source.format.toUpperCase()} → ${request.format.label}';

    final (status, detail) = switch (stage) {
      .queued => (null, ConvertMessages.waitingForSlot),
      .downloading || .processing => (
        progress.fraction == null ? null : DownloadMessages.percent((progress.fraction! * 100).round()),
        [action, target, if (progress.etaSeconds case final eta? when eta > 0) FormatUtils.eta(eta)].join(' · '),
      ),
      .saving => (null, DownloadMessages.saving),
      .done => (null, target),
      .failed => (null, progress.errorMessage ?? ConvertMessages.failed),
      .cancelled => (null, ConvertMessages.cancelled),
    };

    return JobCard(
      title: source.title,
      kind: request.format.kind,
      stage: stage,
      image: source.thumbnailPath == null ? null : LocalMedia.image(source.thumbnailPath!),
      progress: progress.fraction,
      status: status,
      detail: detail,
      actions: switch (stage) {
        .queued || .downloading || .processing => [
          AppIconButton(icon: Symbols.close_rounded, label: ConvertMessages.cancelConvert, onPressed: notifier.cancel),
        ],
        .failed || .cancelled => [
          TonalButton(label: ConvertMessages.tryAgain, icon: Symbols.refresh_rounded, onPressed: notifier.reset),
        ],
        .saving || .done => const [],
      },
    );
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/job_card.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_job/tool_job_notifier.dart';

/// The running tool as a [JobCard] with Cancel, or its failure with Try again.
class const ToolJobPanel({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toolJobProvider(tool));
    final notifier = ref.read(toolJobProvider(tool).notifier);
    final request = state.request;
    final progress = state.progress;
    final stage = state.stage;
    if (request == null || progress == null || stage == null) {
      return const SizedBox.shrink();
    }
    final source = request.sources.first;
    final title = request.sources.length > 1
        ? '${source.title} · ${ToolsMessages.fileCount(request.sources.length)}'
        : source.title;

    final (status, detail) = switch (stage) {
      .queued => (null, ToolsMessages.waiting),
      .downloading || .processing => (
        progress.fraction == null ? null : DownloadMessages.percent((progress.fraction! * 100).round()),
        [tool.title, if (progress.etaSeconds case final eta? when eta > 0) FormatUtils.eta(eta)].join(' · '),
      ),
      .saving => (null, DownloadMessages.saving),
      .done => (null, tool.title),
      .failed => (null, progress.errorMessage ?? ToolsMessages.failed),
      .cancelled => (null, ToolsMessages.cancelled),
    };

    return JobCard(
      title: title,
      kind: request.outputKind,
      stage: stage,
      image: source.thumbnailPath == null ? null : LocalMedia.image(source.thumbnailPath!),
      progress: progress.fraction,
      status: status,
      detail: detail,
      actions: switch (stage) {
        .queued || .downloading || .processing => [
          AppIconButton(icon: Symbols.close_rounded, label: ToolsMessages.cancelJob, onPressed: notifier.cancel),
        ],
        .failed || .cancelled => [
          TonalButton(label: ToolsMessages.tryAgain, icon: Symbols.refresh_rounded, onPressed: notifier.reset),
        ],
        .saving || .done => const [],
      },
    );
  }
}

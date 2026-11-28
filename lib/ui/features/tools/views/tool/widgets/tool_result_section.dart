import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_job/tool_job_notifier.dart';

/// What the tool made: previews of the first results, how many, and the
/// size before → after. Its actions (ToolResultActions) are pinned below.
class const ToolResultSection({super.key, required final Tool tool}) extends ConsumerWidget {
  static const _maxPreviews = 6;
  static const _previewWidth = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toolJobProvider(tool));
    final request = state.request;
    final results = state.results;
    if (request == null) {
      return const SizedBox.shrink();
    }
    final before = request.sources.fold(0, (total, source) => total + source.sizeBytes);
    final single = results.length == 1;
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.lg,
        children: [
          if (single)
            MediaThumbnail(
              kind: results.first.kind,
              image: state.thumbnails.first == null ? null : LocalMedia.image(state.thumbnails.first!),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (index, item) in results.take(_maxPreviews).indexed)
                  SizedBox(
                    width: _previewWidth,
                    child: MediaThumbnail(
                      kind: item.kind,
                      image: state.thumbnails[index] == null ? null : LocalMedia.image(state.thumbnails[index]!),
                    ),
                  ),
              ],
            ),
          Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(ToolsMessages.resultTitle(results.length), style: context.text.bodyStrong),
              Text(
                [
                  ToolsMessages.resultBody,
                  ToolsMessages.sizeChange(FormatUtils.bytes(before), FormatUtils.bytes(state.resultBytes)),
                ].join(' · '),
                maxLines: 2,
                overflow: .ellipsis,
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

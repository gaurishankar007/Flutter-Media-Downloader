import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_job/tool_job_notifier.dart';

/// Open (the item, or the post page of several) · Share, then Done. Pinned at
/// the bottom of the tool screen once the job is done.
class const ToolResultActions({super.key, required final Tool tool, required final VoidCallback onDone})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toolJobProvider(tool));
    final notifier = ref.read(toolJobProvider(tool).notifier);
    final results = state.results;
    final groupId = state.groupId;

    void open() {
      if (groupId != null) {
        context.router.push(LibraryPostRoute(groupId: groupId));
      } else if (results.firstOrNull case final item?) {
        context.router.push(MediaViewerRoute(initialId: item.id, ids: [item.id]));
      }
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: TonalButton(
                label: ToolsMessages.open,
                icon: Symbols.open_in_new_rounded,
                expand: true,
                onPressed: results.isEmpty ? null : open,
              ),
            ),
            Expanded(
              child: TonalButton(
                label: CommonMessages.share,
                icon: Symbols.ios_share_rounded,
                expand: true,
                onPressed: results.isEmpty ? null : notifier.share,
              ),
            ),
          ],
        ),
        GradientButton(label: ToolsMessages.done, icon: Symbols.check_rounded, expand: true, onPressed: onDone),
      ],
    );
  }
}

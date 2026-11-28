import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_back_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_job/tool_job_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_job_panel.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_result_actions.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_result_section.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_source_list.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_source_tiles.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/tool_start_button.dart';

/// One tool: pick files → options → run → result, in one screen.
/// See docs/features/tools.md#tool-screen.
@RoutePage()
class const ToolScreen({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSources = ref.watch(toolSourcesProvider(tool).select((state) => state.sources.isNotEmpty));
    final job = ref.watch(toolJobProvider(tool).select((state) => (hasJob: state.hasJob, done: state.isDone)));
    final sourcesNotifier = ref.read(toolSourcesProvider(tool).notifier);

    ref
      ..listenMessages(toolSourcesProvider(tool), context)
      ..listenMessages(toolJobProvider(tool), context);

    void done() {
      ref.read(toolJobProvider(tool).notifier).reset();
      sourcesNotifier.clear();
    }

    return Scaffold(
      body: ScreenScrollView(
        bottomAction: switch ((job.hasJob, job.done)) {
          (true, true) => ToolResultActions(tool: tool, onDone: done),
          (false, _) when hasSources => ToolStartButton(tool: tool),
          _ => null,
        },
        children: [
          const ScreenBackButton(),
          ScreenHeader(title: tool.title, subtitle: tool.body),
          if (job.hasJob)
            if (job.done) ToolResultSection(tool: tool) else ToolJobPanel(tool: tool)
          else ...[
            SectionHeader(
              title: tool.multiple ? ToolsMessages.pickFiles : ToolsMessages.pickFile,
              trailing: hasSources && tool.multiple
                  ? GhostButton(label: ToolsMessages.clearAll, onPressed: sourcesNotifier.clear)
                  : null,
            ),
            if (hasSources) ToolSourceList(tool: tool) else ToolSourceTiles(tool: tool),
            if (hasSources) ToolOptions(tool: tool),
          ],
        ],
      ),
    );
  }
}

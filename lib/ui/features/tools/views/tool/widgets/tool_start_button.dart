import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_job/tool_job_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';

/// Runs the tool ("Make PDF", "Trim"…); disabled until the options make sense.
class const ToolStartButton({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(toolOptionsProvider(tool).select((state) => state.request));
    return GradientButton(
      label: tool.startLabel,
      icon: tool.icon,
      expand: true,
      onPressed: request == null ? null : () => ref.read(toolJobProvider(tool).notifier).start(request),
    );
  }
}

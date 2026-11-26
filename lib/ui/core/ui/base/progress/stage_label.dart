import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/job_stage.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A coloured dot and the stage name. Colour is never the only signal: the
/// text always says the stage.
class const StageLabel({super.key, required final JobStage stage}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (color, label) = switch (stage) {
      .queued => (colors.textMuted, JobStageMessages.queued),
      .downloading => (colors.primaryText, JobStageMessages.downloading),
      .processing => (colors.secondary, JobStageMessages.processing),
      .saving => (colors.secondary, JobStageMessages.saving),
      .done => (colors.success, JobStageMessages.done),
      .failed => (colors.error, JobStageMessages.failed),
      .cancelled => (colors.textMuted, JobStageMessages.cancelled),
    };
    return Row(
      mainAxisSize: .min,
      spacing: AppSpacing.xs + 2,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: .circle),
        ),
        Text(label, style: context.text.caption.copyWith(color: color)),
      ],
    );
  }
}

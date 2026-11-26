import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/job_stage.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/ui/base/media/site_badge.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/core/ui/base/progress/stage_label.dart';

/// A download or conversion job: thumbnail, title, stage, progress while
/// active, and [actions] (Cancel while active; Share / Remove when done).
/// Pulses once in `success` when the job finishes.
class const JobCard({
  super.key,
  required final String title,
  required final MediaKind kind,
  required final JobStage stage,
  final ImageProvider? image,
  final Site? site,
  final double? progress,

  /// Live numbers next to the stage, e.g. "64% · 3.2 MB/s".
  final String? status,

  /// Second line, e.g. "1080p MP4 · 45 s left" or "720p MP4 · 84 MB".
  final String? detail,
  final List<Widget> actions = const [],
  final Object? heroTag,
  final VoidCallback? onTap,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pulse = useAnimationController(duration: const Duration(milliseconds: 900));
    final previousStage = usePrevious(stage);

    useEffect(() {
      if (previousStage != null && previousStage != .done && stage == .done) {
        HapticFeedback.lightImpact();
        if (!MediaQuery.disableAnimationsOf(context)) {
          pulse.forward(from: 0);
        }
      }
      return null;
    }, [stage]);

    final showProgress = stage == .queued || stage.isActive;
    // Two or more labelled buttons (Dismiss + Retry) leave too little room
    // for the detail on a phone: they get their own row under it.
    final stackActions = actions.where((action) => action is! AppIconButton).length > 1;
    final detailText = Text(
      detail ?? '',
      maxLines: 2,
      overflow: .ellipsis,
      style: context.text.label.copyWith(color: colors.textSecondary),
    );

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = pulse.isAnimating ? 1 - Curves.easeOut.transform(pulse.value) : 0.0;
        if (glow == 0) {
          return child!;
        }
        // Shadow behind the card, ring on top of it.
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            boxShadow: [
              BoxShadow(
                color: colors.success.withValues(alpha: 0.45 * glow),
                blurRadius: 24 * glow,
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: .all(color: colors.success.withValues(alpha: glow), width: 1.5),
          ),
          child: child,
        );
      },
      child: AppCard(
        onTap: onTap,
        padding: const .all(AppSpacing.md),
        child: Column(
          spacing: AppSpacing.md,
          children: [
            Row(
              crossAxisAlignment: .start,
              spacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 104,
                  child: MediaThumbnail(kind: kind, image: image, heroTag: heroTag),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: AppSpacing.xs + 2,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: context.text.bodyStrong.copyWith(height: 1.3),
                      ),
                      Row(
                        spacing: AppSpacing.sm,
                        children: [
                          if (site != null) SiteBadge(site: site!, size: 16),
                          StageLabel(stage: stage),
                          if (status != null)
                            Flexible(
                              child: Text(
                                status!,
                                maxLines: 1,
                                overflow: .ellipsis,
                                style: context.text.numeric.copyWith(color: colors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showProgress) GradientProgressBar(value: stage == .queued ? null : progress),
            if (stackActions) ...[
              if (detail != null) Align(alignment: .centerLeft, child: detailText),
              Align(
                alignment: .centerRight,
                child: Wrap(alignment: .end, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
              ),
            ] else if (detail != null || actions.isNotEmpty)
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Expanded(child: detailText),
                  ...actions,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

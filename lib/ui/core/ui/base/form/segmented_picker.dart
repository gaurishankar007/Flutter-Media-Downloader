import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/app_motion.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// One choice in a [SegmentedPicker].
typedef Segment<T> = ({T value, String label, IconData? icon});

/// Equal-width segments on a raised track, with an Aurora pill that slides to
/// the selected one (Video / Audio / Photos, Convert / Compress).
class const SegmentedPicker<T>({
  super.key,
  required final List<Segment<T>> segments,
  required final T selected,
  required final ValueChanged<T> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = segments.indexWhere((segment) => segment.value == selected);
    final count = segments.length;

    return Container(
      height: 48,
      padding: const .all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: .all(color: colors.outline),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context) ? .zero : AppMotion.normal,
              curve: AppMotion.standard,
              alignment: Alignment(count == 1 ? 0 : -1 + 2 * index / (count - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.aurora,
                    borderRadius: const .all(.circular(AppRadius.md - AppSpacing.xs)),
                    boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: Semantics(
                    selected: segment.value == selected,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(segment.value),
                      borderRadius: const .all(.circular(AppRadius.md - AppSpacing.xs)),
                      child: _content(context, segment, selected: segment.value == selected),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Segment<T> segment, {required bool selected}) {
    final foreground = selected ? context.colors.onPrimary : context.colors.textSecondary;
    return Row(
      mainAxisAlignment: .center,
      spacing: AppSpacing.xs + 2,
      children: [
        if (segment.icon != null) Icon(segment.icon, size: 18, color: foreground, fill: selected ? 1 : 0),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: context.text.label.copyWith(color: foreground, fontWeight: .w600),
            child: Text(segment.label, maxLines: 1, overflow: .ellipsis),
          ),
        ),
      ],
    );
  }
}

import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/video_clip.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';

/// Edits the selected trim clip: a range slider (the player jumps to the
/// handle being dragged, so you see that frame) and Start here / End here,
/// which take the player's position.
class const ClipEditor({
  super.key,
  required final VideoClip clip,
  required final double duration,
  required final ValueChanged<VideoClip> onChanged,
  required final ValueChanged<double>? onSeek,
  required final VoidCallback? onStartHere,
  required final VoidCallback? onEndHere,
  final VoidCallback? onDragStart,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        RangeSlider(
          values: RangeValues(clip.start.clamp(0, duration), clip.end.clamp(0, duration)),
          max: duration,
          activeColor: colors.primary,
          inactiveColor: colors.surfaceRaised,
          labels: RangeLabels(FormatUtils.clipTime(clip.start), FormatUtils.clipTime(clip.end)),
          onChangeStart: (_) => onDragStart?.call(),
          onChanged: (values) {
            final movedStart = values.start != clip.start;
            onChanged(VideoClip(start: values.start, end: values.end));
            onSeek?.call(movedStart ? values.start : values.end);
          },
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: TonalButton(
                label: ToolsMessages.startHere,
                icon: Symbols.first_page_rounded,
                expand: true,
                onPressed: onStartHere,
              ),
            ),
            Expanded(
              child: TonalButton(
                label: ToolsMessages.endHere,
                icon: Symbols.last_page_rounded,
                expand: true,
                onPressed: onEndHere,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

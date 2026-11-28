import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';

/// One PDF page: its thumbnail turned [quarterTurns], its original number,
/// and Rotate / Delete. [highlighted] while another page is dragged over it.
class const PageTile({
  super.key,
  required final int number,
  required final int quarterTurns,
  required final VoidCallback onRotate,
  required final VoidCallback onDelete,
  final String? thumbnail,
  final bool highlighted = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: highlighted ? colors.primary : colors.outline, width: highlighted ? 2 : 1),
      ),
      clipBehavior: .antiAlias,
      child: Padding(
        padding: const .all(AppSpacing.xs),
        child: Column(
          mainAxisSize: .min,
          spacing: AppSpacing.xs,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ColoredBox(
                color: colors.surfaceRaised,
                child: thumbnail == null
                    ? Icon(Symbols.description_rounded, color: colors.textMuted)
                    : RotatedBox(
                        quarterTurns: quarterTurns,
                        child: Image(image: LocalMedia.image(thumbnail!), fit: .contain),
                      ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$number',
                    textAlign: .center,
                    style: context.text.label.copyWith(color: colors.textSecondary),
                  ),
                ),
                AppIconButton(
                  icon: Symbols.rotate_right_rounded,
                  label: ToolsMessages.rotatePage,
                  size: 32,
                  onPressed: onRotate,
                ),
                AppIconButton(
                  icon: Symbols.delete_rounded,
                  label: ToolsMessages.deletePage,
                  size: 32,
                  destructive: true,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

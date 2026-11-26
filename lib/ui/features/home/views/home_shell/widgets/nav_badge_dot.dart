import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// The small warning dot on a tab that needs attention (an engine update).
class const NavBadgeDot({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colors.warning,
        shape: .circle,
        border: .all(color: colors.surface, width: 1.5),
      ),
    );
  }
}

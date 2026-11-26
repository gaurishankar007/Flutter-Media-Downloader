import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';

/// A single horizontally scrolling row of chips. Wraps onto more lines
/// instead when [wrap] is true (large text sizes, wide screens).
class const ChipRow({super.key, required final List<Widget> children, final bool wrap = false})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      clipBehavior: .none,
      child: Row(spacing: AppSpacing.sm, children: children),
    );
  }
}

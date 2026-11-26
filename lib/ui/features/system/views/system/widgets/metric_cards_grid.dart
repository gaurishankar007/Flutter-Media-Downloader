import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';

/// The System page cards: one column on phones, two (equal height per row)
/// once there's room.
class const MetricCardsGrid({super.key, required final List<Widget> children}) extends StatelessWidget {
  static const _minCardWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _minCardWidth * 2 + AppSpacing.lg ? 2 : 1;
        return Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.lg,
          children: [
            for (var start = 0; start < children.length; start += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: .stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    for (final child in children.skip(start).take(columns)) Expanded(child: child),
                    // An odd last card keeps its column width.
                    if (children.length - start < columns) const Spacer(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

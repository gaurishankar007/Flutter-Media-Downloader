import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A screen's large title and subtitle.
class const ScreenHeader({super.key, required final String title, final String? subtitle, final bool large = false})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(top: AppSpacing.xl, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs + 2,
        children: [
          Text(title, style: large ? context.text.display : context.text.screenTitle),
          if (subtitle != null) Text(subtitle!, style: context.text.body.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

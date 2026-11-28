import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A short note under the options; [warning] when it explains why the tool
/// can't start yet.
class const OptionNote({super.key, required final String text, final bool warning = false}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(top: AppSpacing.md),
      child: Text(
        text,
        style: context.text.label.copyWith(color: warning ? context.colors.warning : context.colors.textSecondary),
      ),
    );
  }
}

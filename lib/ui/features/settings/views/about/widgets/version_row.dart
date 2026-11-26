import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// "App   1.0.0 (1)".
class const VersionRow({super.key, required final String label, required final String value}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.text.bodyStrong)),
          Text(value, style: context.text.numeric.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

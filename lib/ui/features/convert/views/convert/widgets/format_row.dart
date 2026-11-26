import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// An icon, a kind name and its formats as small pills.
class const FormatRow({
  super.key,
  required final IconData icon,
  required final String title,
  required final List<String> formats,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Icon(icon, color: colors.primaryText),
        SizedBox(width: 64, child: Text(title, style: context.text.bodyStrong)),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs + 2,
            children: [
              for (final format in formats)
                Container(
                  padding: const .symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: AppRadius.smAll,
                    border: .all(color: colors.outline),
                  ),
                  child: Text(format, style: context.text.caption.copyWith(color: colors.textSecondary)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

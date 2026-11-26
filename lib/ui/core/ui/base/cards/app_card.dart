import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A surface card. Separated from the background by colour, plus a 1px
/// outline in light mode.
class const AppCard({
  super.key,
  required final Widget child,
  final EdgeInsetsGeometry padding = const .all(AppSpacing.lg),
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: context.isDark ? .none : BorderSide(color: colors.outline),
      ),
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

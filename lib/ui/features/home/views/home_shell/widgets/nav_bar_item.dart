import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/home/models/nav_destination.dart';
import 'package:media_tool/ui/features/home/views/home_shell/widgets/nav_badge_dot.dart';

/// One bottom-bar tab: gradient pill behind the icon when selected.
class const NavBarItem({
  super.key,
  required final NavDestination destination,
  required final bool selected,
  required final VoidCallback onTap,
  final bool badge = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: .center,
          spacing: AppSpacing.xs,
          children: [
            AnimatedContainer(
              duration: AppMotion.normal,
              curve: AppMotion.standard,
              width: selected ? 48 : 36,
              height: 30,
              decoration: BoxDecoration(gradient: selected ? AppGradients.aurora : null, borderRadius: AppRadius.pill),
              child: Stack(
                alignment: .center,
                clipBehavior: .none,
                children: [
                  Icon(
                    destination.icon,
                    size: 22,
                    fill: selected ? 1 : 0,
                    color: selected ? colors.onPrimary : colors.textMuted,
                  ),
                  if (badge) const Positioned(top: 2, right: 6, child: NavBadgeDot()),
                ],
              ),
            ),
            // Five tabs on a 320 dp phone: shrink a long label rather than clip it.
            Padding(
              padding: const .symmetric(horizontal: 2),
              child: FittedBox(
                fit: .scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: context.text.caption.copyWith(color: selected ? colors.textPrimary : colors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

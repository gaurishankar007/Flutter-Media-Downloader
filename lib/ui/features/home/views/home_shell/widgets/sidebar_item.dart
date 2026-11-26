import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/home/models/nav_destination.dart';
import 'package:media_tool/ui/features/home/views/home_shell/widgets/nav_badge_dot.dart';

/// One sidebar row: tinted background and gradient icon when selected.
class const SidebarItem({
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
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: context.isDark ? 0.18 : 0.10) : Colors.transparent,
          borderRadius: AppRadius.mdAll,
        ),
        child: Material(
          type: .transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdAll,
            child: Padding(
              padding: const .symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  ShaderMask(
                    shaderCallback: AppGradients.aurora.createShader,
                    blendMode: selected ? .srcIn : .dst,
                    child: Icon(
                      destination.icon,
                      fill: selected ? 1 : 0,
                      color: selected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.text.bodyStrong.copyWith(
                        color: selected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                  if (badge) const NavBadgeDot(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

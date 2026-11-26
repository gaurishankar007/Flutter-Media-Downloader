import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/features/home/models/nav_destination.dart';
import 'package:media_downloader/ui/features/home/views/home_shell/widgets/nav_bar_item.dart';

/// Floating, blurred bottom bar for phones and small tablets.
class const AppNavigationBar({
  super.key,
  required final int selectedIndex,
  required final ValueChanged<int> onSelected,
  final Set<NavDestination> badges = const {},
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      minimum: const .fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: AppRadius.xlAll,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                padding: const .symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.82),
                  borderRadius: AppRadius.xlAll,
                  border: .all(color: colors.outline),
                ),
                child: Row(
                  children: [
                    for (final destination in NavDestination.values)
                      Expanded(
                        child: NavBarItem(
                          destination: destination,
                          selected: destination.index == selectedIndex,
                          badge: badges.contains(destination),
                          onTap: () => onSelected(destination.index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

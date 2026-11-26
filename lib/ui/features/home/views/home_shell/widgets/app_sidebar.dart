import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/icons/gradient_icon_tile.dart';
import 'package:media_tool/ui/features/home/models/nav_destination.dart';
import 'package:media_tool/ui/features/home/views/home_shell/widgets/sidebar_item.dart';

/// Left sidebar for tablets and macOS.
class const AppSidebar({
  super.key,
  required final int selectedIndex,
  required final ValueChanged<int> onSelected,
  final Set<NavDestination> badges = const {},
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const .all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: AppSpacing.xs,
            children: [
              Padding(
                padding: const .only(left: AppSpacing.xs, top: AppSpacing.sm, bottom: AppSpacing.xl),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    const GradientIconTile(icon: Symbols.download_rounded, size: 36),
                    Expanded(
                      child: Text(
                        AboutMessages.appName,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: context.text.headline,
                      ),
                    ),
                  ],
                ),
              ),
              for (final destination in NavDestination.values)
                SidebarItem(
                  destination: destination,
                  selected: destination.index == selectedIndex,
                  badge: badges.contains(destination),
                  onTap: () => onSelected(destination.index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

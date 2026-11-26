import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/app_theme_mode.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';

/// System / Dark / Light.
class const ThemeModePicker({
  super.key,
  required final AppThemeMode selected,
  required final ValueChanged<AppThemeMode> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final mode in AppThemeMode.values)
          SelectChip(
            label: switch (mode) {
              .system => SettingsMessages.themeSystem,
              .dark => SettingsMessages.themeDark,
              .light => SettingsMessages.themeLight,
            },
            icon: switch (mode) {
              .system => Symbols.brightness_auto_rounded,
              .dark => Symbols.dark_mode_rounded,
              .light => Symbols.light_mode_rounded,
            },
            selected: mode == selected,
            onSelected: () => onSelected(mode),
          ),
      ],
    );
  }
}

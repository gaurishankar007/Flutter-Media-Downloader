import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/theme_mode_picker.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';

/// Theme: System / Dark / Light.
class const AppearanceSettingsSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((state) => state.settings.themeMode));
    return SettingsSection(
      title: SettingsMessages.appearance,
      children: [
        SettingsTile(
          icon: Symbols.contrast_rounded,
          title: SettingsMessages.theme,
          below: ThemeModePicker(selected: themeMode, onSelected: ref.read(settingsProvider.notifier).setThemeMode),
        ),
      ],
    );
  }
}

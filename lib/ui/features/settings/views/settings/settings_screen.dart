import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/routing/routes.gr.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/about_settings_section.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/appearance_settings_section.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/cookies_settings_section.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/downloads_settings_section.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/engine_settings_section.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/library_storage_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';

/// Settings tab. Settings and engine messages are shown by the shell, so
/// they also appear when changed from other tabs. See docs/features/settings.md.
@RoutePage()
class const SettingsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenScrollView(
      children: [
        const ScreenHeader(title: SettingsMessages.title, subtitle: SettingsMessages.subtitle),
        const DownloadsSettingsSection(),
        const LibraryStorageSection(),
        const CookiesSettingsSection(),
        const EngineSettingsSection(),
        const AppearanceSettingsSection(),
        const AboutSettingsSection(),
        if (kDebugMode)
          SettingsSection(
            title: SettingsMessages.developer,
            children: [
              SettingsTile(
                icon: Symbols.palette_rounded,
                title: SettingsMessages.designGallery,
                subtitle: SettingsMessages.designGalleryBody,
                onTap: () => context.router.push(const DesignGalleryRoute()),
              ),
            ],
          ),
      ],
    );
  }
}

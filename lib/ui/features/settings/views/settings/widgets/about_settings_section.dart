import 'package:auto_route/auto_route.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/routing/routes.gr.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';
import 'package:media_downloader/ui/startup/rights_notice_dialog.dart';

/// The rights notice and the About screen.
class const AboutSettingsSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: SettingsMessages.about,
      children: [
        SettingsTile(
          icon: Symbols.gavel_rounded,
          title: SettingsMessages.rightsNotice,
          subtitle: SettingsMessages.rightsNoticeBody,
          onTap: () => showRightsNoticeDialog(context, dismissible: true),
        ),
        SettingsTile(
          icon: Symbols.info_rounded,
          title: SettingsMessages.aboutTile,
          subtitle: SettingsMessages.aboutBody,
          onTap: () => context.router.push(const AboutRoute()),
        ),
      ],
    );
  }
}

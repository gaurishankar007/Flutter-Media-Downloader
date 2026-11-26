import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_back_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/download/providers/engine_status/engine_status_notifier.dart';
import 'package:media_tool/ui/features/settings/providers/about/about_notifier.dart';
import 'package:media_tool/ui/features/settings/views/about/widgets/version_row.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_section.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_tile.dart';
import 'package:media_tool/ui/startup/rights_notice_dialog.dart';

/// Settings → About: rights notice, versions, licences and the error log.
@RoutePage()
class const AboutScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenMessages(aboutProvider, context);
    final appVersion = ref.watch(aboutProvider.select((state) => state.appVersion));
    final ytDlpVersion = ref.watch(engineStatusProvider.select((state) => state.info?.ytDlpVersion));

    return Scaffold(
      body: ScreenScrollView(
        children: [
          const ScreenBackButton(),
          const ScreenHeader(title: AboutMessages.title, subtitle: AboutMessages.subtitle),
          SettingsSection(
            title: AboutMessages.versions,
            children: [
              VersionRow(label: AboutMessages.appVersion, value: appVersion ?? AboutMessages.unknown),
              VersionRow(label: AboutMessages.ytDlpVersion, value: ytDlpVersion ?? AboutMessages.unknown),
            ],
          ),
          SettingsSection(
            title: AboutMessages.more,
            children: [
              SettingsTile(
                icon: Symbols.gavel_rounded,
                title: SettingsMessages.rightsNotice,
                subtitle: SettingsMessages.rightsNoticeBody,
                onTap: () => showRightsNoticeDialog(context, dismissible: true),
              ),
              SettingsTile(
                icon: Symbols.license_rounded,
                title: AboutMessages.licences,
                subtitle: AboutMessages.licencesBody,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AboutMessages.appName,
                  applicationVersion: appVersion,
                ),
              ),
              SettingsTile(
                icon: Symbols.bug_report_rounded,
                title: AboutMessages.errorLog,
                subtitle: AboutMessages.errorLogBody,
                trailing: TonalButton(
                  label: AboutMessages.copy,
                  icon: Symbols.content_copy_rounded,
                  onPressed: ref.read(aboutProvider.notifier).copyErrorLog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

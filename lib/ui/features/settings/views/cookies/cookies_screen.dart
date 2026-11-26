import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/ui/base/dialog/confirm_dialog.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_back_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/settings/providers/cookies/cookies_notifier.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_tool/ui/features/settings/views/cookies/widgets/cookie_browser_picker.dart';
import 'package:media_tool/ui/features/settings/views/cookies/widgets/cookies_how_to_card.dart';
import 'package:media_tool/ui/features/settings/views/cookies/widgets/site_cookies_row.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_section.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_tile.dart';

/// Settings → Cookies: import a cookies.txt per site, see which sites have
/// cookies, remove them; macOS can read a browser's cookies instead.
/// See docs/features/settings.md#cookies.
@RoutePage()
class const CookiesScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenMessages(cookiesProvider, context);
    final state = ref.watch(cookiesProvider);
    final notifier = ref.read(cookiesProvider.notifier);
    final browser = ref.watch(settingsProvider.select((settings) => settings.settings.cookieBrowser));

    Future<void> confirmRemove(Site site) async {
      final confirmed = await showConfirmDialog(
        context,
        title: CookiesMessages.removeTitle(site.label),
        body: CookiesMessages.removeBody,
        confirmLabel: CommonMessages.remove,
        destructive: true,
      );
      if (confirmed) {
        await notifier.remove(site);
      }
    }

    return Scaffold(
      body: ScreenScrollView(
        children: [
          const ScreenBackButton(),
          const ScreenHeader(title: CookiesMessages.title, subtitle: CookiesMessages.subtitle),
          SettingsSection(
            title: CookiesMessages.sites,
            children: [
              for (final site in Site.values)
                SiteCookiesRow(
                  site: site,
                  cookies: state.cookiesFor(site),
                  busy: state.busySite == site,
                  onImport: state.busySite == null ? () => notifier.import(site) : null,
                  onRemove: () => confirmRemove(site),
                ),
            ],
          ),
          if (state.supportsBrowserCookies)
            SettingsSection(
              title: CookiesMessages.browser,
              children: [
                SettingsTile(
                  icon: Symbols.public_rounded,
                  title: CookiesMessages.browser,
                  subtitle: CookiesMessages.browserBody,
                  below: CookieBrowserPicker(selected: browser, onSelected: notifier.setBrowser),
                ),
              ],
            ),
          const SectionHeader(title: CookiesMessages.howTo),
          const CookiesHowToCard(),
        ],
      ),
    );
  }
}

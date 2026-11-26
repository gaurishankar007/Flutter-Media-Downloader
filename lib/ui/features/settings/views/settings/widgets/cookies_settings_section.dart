import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/features/settings/providers/cookies/cookies_notifier.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_section.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_tile.dart';

/// Opens the Cookies screen; says how many sites have cookies.
class const CookiesSettingsSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cookiesProvider.select((state) => state.cookies.length));
    return SettingsSection(
      title: SettingsMessages.cookies,
      children: [
        SettingsTile(
          icon: Symbols.cookie_rounded,
          title: SettingsMessages.cookiesTile,
          subtitle: SettingsMessages.cookiesBody(count),
          onTap: () => context.router.push(const CookiesRoute()),
        ),
      ],
    );
  }
}

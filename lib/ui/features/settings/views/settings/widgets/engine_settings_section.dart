import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/features/download/providers/engine_status/engine_status_notifier.dart';
import 'package:media_downloader/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/engine_update_banner.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_switch_tile.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';

/// yt-dlp version, Update, and the launch check.
class const EngineSettingsSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineStatusProvider);
    final checkOnLaunch = ref.watch(settingsProvider.select((state) => state.settings.checkEngineOnLaunch));
    final busy = engine.updateStatus != .idle;

    return SettingsSection(
      title: SettingsMessages.engine,
      children: [
        SettingsTile(
          icon: Symbols.update_rounded,
          title: SettingsMessages.engineVersion,
          subtitle: switch (engine.engineStatus) {
            .failed => SettingsMessages.engineUnavailable,
            _ => SettingsMessages.engineBody(engine.info?.ytDlpVersion),
          },
          trailing: TonalButton(
            label: engine.updateStatus == .updating ? SettingsMessages.updating : SettingsMessages.update,
            onPressed: engine.engineStatus == .ready && !busy ? ref.read(engineStatusProvider.notifier).update : null,
          ),
          below: switch (engine.availableVersion) {
            final version? => EngineUpdateBanner(version: version),
            null => null,
          },
        ),
        SettingsSwitchTile(
          icon: Symbols.schedule_rounded,
          title: SettingsMessages.checkOnLaunch,
          subtitle: SettingsMessages.checkOnLaunchBody,
          value: checkOnLaunch,
          onChanged: ref.read(settingsProvider.notifier).setCheckEngineOnLaunch,
        ),
      ],
    );
  }
}

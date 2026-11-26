import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/audio_quality_picker.dart';
import 'package:media_downloader/ui/features/settings/views/settings/widgets/video_quality_picker.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_section.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_switch_tile.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';

/// Default qualities, iPhone-compatible output and photo format.
class const DownloadsSettingsSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider.select((state) => state.settings));
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: SettingsMessages.downloads,
      children: [
        SettingsTile(
          icon: Symbols.high_quality_rounded,
          title: SettingsMessages.defaultVideoQuality,
          below: VideoQualityPicker(
            selected: settings.defaultVideoQuality,
            onSelected: notifier.setDefaultVideoQuality,
          ),
        ),
        SettingsTile(
          icon: Symbols.music_note_rounded,
          title: SettingsMessages.defaultAudioQuality,
          below: AudioQualityPicker(
            selected: settings.defaultAudioQuality,
            onSelected: notifier.setDefaultAudioQuality,
          ),
        ),
        SettingsSwitchTile(
          icon: Symbols.phone_iphone_rounded,
          title: SettingsMessages.iphoneCompatible,
          subtitle: SettingsMessages.iphoneCompatibleBody,
          value: settings.iphoneCompatible,
          onChanged: notifier.setIphoneCompatible,
        ),
        SettingsSwitchTile(
          icon: Symbols.photo_rounded,
          title: SettingsMessages.photosToJpg,
          subtitle: SettingsMessages.photosToJpgBody,
          value: settings.photosToJpg,
          onChanged: notifier.setPhotosToJpg,
        ),
      ],
    );
  }
}

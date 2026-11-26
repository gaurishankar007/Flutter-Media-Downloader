import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/ui/base/dialog/confirm_dialog.dart';
import 'package:media_tool/ui/core/ui/base/states/shimmer_box.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_tool/ui/features/settings/providers/storage/storage_notifier.dart';
import 'package:media_tool/ui/features/settings/views/settings/widgets/storage_breakdown.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_section.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_switch_tile.dart';
import 'package:media_tool/ui/features/settings/widgets/settings_tile.dart';

/// The remove-after-save prompt, storage used and "clear saved items".
class const LibraryStorageSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenMessages(storageProvider, context);
    final askRemove = ref.watch(settingsProvider.select((state) => state.settings.askRemoveAfterSave));
    final storage = ref.watch(storageProvider);
    final usage = storage.usage;

    Future<void> confirmClear() async {
      if (usage == null || usage.savedCount == 0) {
        return;
      }
      final confirmed = await showConfirmDialog(
        context,
        title: SettingsMessages.clearSavedTitle(usage.savedCount),
        body: SettingsMessages.clearSavedConfirmBody,
        confirmLabel: SettingsMessages.clear,
        destructive: true,
      );
      if (confirmed) {
        await ref.read(storageProvider.notifier).clearSaved();
      }
    }

    return SettingsSection(
      title: SettingsMessages.libraryStorage,
      children: [
        SettingsSwitchTile(
          icon: Symbols.delete_sweep_rounded,
          title: SettingsMessages.askRemove,
          subtitle: SettingsMessages.askRemoveBody,
          value: askRemove,
          onChanged: ref.read(settingsProvider.notifier).setAskRemoveAfterSave,
        ),
        SettingsTile(
          icon: Symbols.storage_rounded,
          title: SettingsMessages.storageUsed,
          trailing: usage == null ? null : Text(FormatUtils.bytes(usage.totalBytes)),
          below: usage == null ? const ShimmerBox(height: 56) : StorageBreakdown(usage: usage),
        ),
        SettingsTile(
          icon: Symbols.cleaning_services_rounded,
          title: SettingsMessages.clearSaved,
          subtitle: usage == null
              ? null
              : SettingsMessages.clearSavedBody(usage.savedCount, FormatUtils.bytes(usage.savedBytes)),
          trailing: storage.clearing
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          onTap: storage.clearing || (usage?.savedCount ?? 0) == 0 ? null : confirmClear,
        ),
      ],
    );
  }
}

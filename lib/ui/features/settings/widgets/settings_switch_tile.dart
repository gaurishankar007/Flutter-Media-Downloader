import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/features/settings/widgets/settings_tile.dart';

/// A [SettingsTile] with a switch; the whole row toggles.
class const SettingsSwitchTile({
  super.key,
  required final IconData icon,
  required final String title,
  required final bool value,
  required final ValueChanged<bool> onChanged,
  final String? subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      ),
    );
  }
}

import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// "Version X is available" in the warning tint, above the engine rows.
class const EngineUpdateBanner({super.key, required final String version}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.14), borderRadius: AppRadius.mdAll),
      // The text wraps on phones: the icon stays on its first line.
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm,
        children: [
          Icon(Symbols.new_releases_rounded, color: colors.warning, size: 20),
          Expanded(child: Text(SettingsMessages.updateAvailable(version), style: context.text.label)),
        ],
      ),
    );
  }
}

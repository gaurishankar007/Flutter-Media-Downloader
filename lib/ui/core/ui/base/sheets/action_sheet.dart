import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/sheets/app_bottom_sheet.dart';

/// One row of an [ActionSheet].
typedef SheetAction = ({IconData icon, String label, VoidCallback onTap, bool destructive});

/// Opens a list of actions (Save to Photos, Share, Delete…). The sheet closes
/// before the tapped action runs.
Future<void> showActionSheet(BuildContext context, {required List<SheetAction> actions, String? title}) =>
    showAppBottomSheet<void>(
      context,
      child: ActionSheet(actions: actions, title: title),
    );

class const ActionSheet({super.key, required final List<SheetAction> actions, final String? title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (title != null)
          Padding(
            padding: const .only(bottom: AppSpacing.sm),
            child: Text(title!, maxLines: 2, overflow: .ellipsis, style: context.text.headline),
          ),
        for (final action in actions)
          InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: () {
              Navigator.of(context).pop();
              action.onTap();
            },
            child: Padding(
              padding: const .symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md + 2),
              child: Row(
                spacing: AppSpacing.lg,
                children: [
                  Icon(action.icon, color: action.destructive ? colors.error : colors.textSecondary),
                  Text(
                    action.label,
                    style: context.text.bodyStrong.copyWith(color: action.destructive ? colors.error : null),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

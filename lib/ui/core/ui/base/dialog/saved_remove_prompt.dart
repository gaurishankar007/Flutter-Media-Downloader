import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';

/// What the user picked in the [SavedRemovePrompt].
typedef SavedRemoveChoice = ({bool remove, bool dontAskAgain});

/// "Saved to Photos. Remove from app?" after a confirmed save. [place] is
/// [SavedPromptMessages.photos] or [SavedPromptMessages.files]. Dismissing
/// counts as Keep.
Future<SavedRemoveChoice> showSavedRemovePrompt(BuildContext context, {required String place}) async =>
    await showDialog<SavedRemoveChoice>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (_) => SavedRemovePrompt(place: place),
    ) ??
    (remove: false, dontAskAgain: false);

class const SavedRemovePrompt({super.key, required final String place}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dontAskAgain = useState(false);
    void close({required bool remove}) =>
        Navigator.of(context).pop<SavedRemoveChoice>((remove: remove, dontAskAgain: dontAskAgain.value));

    return Dialog(
      insetPadding: const .all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const .fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: AppSpacing.md,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.15), shape: .circle),
                child: Icon(Symbols.check_circle_rounded, color: colors.success, fill: 1, size: 28),
              ),
              Text(SavedPromptMessages.title(place), style: context.text.title),
              Padding(
                padding: const .only(right: AppSpacing.sm),
                child: Text(
                  SavedPromptMessages.body(place),
                  style: context.text.body.copyWith(color: colors.textSecondary),
                ),
              ),
              MergeSemantics(
                child: InkWell(
                  onTap: () => dontAskAgain.value = !dontAskAgain.value,
                  borderRadius: AppRadius.smAll,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Checkbox(
                        value: dontAskAgain.value,
                        onChanged: (value) => dontAskAgain.value = value ?? false,
                        activeColor: colors.primary,
                        side: BorderSide(color: colors.textMuted, width: 1.5),
                        shape: const RoundedRectangleBorder(borderRadius: .all(.circular(5))),
                      ),
                      Padding(
                        padding: const .only(right: AppSpacing.sm),
                        child: Text(SavedPromptMessages.dontAskAgain, style: context.text.label),
                      ),
                    ],
                  ),
                ),
              ),
              // Stacks the buttons when they don't fit side by side (narrow phones).
              OverflowBar(
                alignment: .end,
                overflowAlignment: .end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: [
                  GhostButton(label: SavedPromptMessages.keep, onPressed: () => close(remove: false)),
                  TonalButton(
                    label: SavedPromptMessages.removeFromApp,
                    icon: Symbols.delete_rounded,
                    destructive: true,
                    onPressed: () => close(remove: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

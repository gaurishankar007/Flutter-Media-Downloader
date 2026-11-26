import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';

/// Asks to confirm an action. Resolves to true only when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (_) => ConfirmDialog(title: title, body: body, confirmLabel: confirmLabel, destructive: destructive),
    ) ??
    false;

class const ConfirmDialog({
  super.key,
  required final String title,
  required final String body,
  required final String confirmLabel,
  final bool destructive = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void close(bool confirmed) => Navigator.of(context).pop(confirmed);

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
              Text(title, style: context.text.title),
              Padding(
                padding: const .only(right: AppSpacing.sm),
                child: Text(body, style: context.text.body.copyWith(color: context.colors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Stacks the buttons when they don't fit side by side (narrow phones).
              OverflowBar(
                alignment: .end,
                overflowAlignment: .end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: [
                  GhostButton(label: CommonMessages.cancel, onPressed: () => close(false)),
                  if (destructive)
                    TonalButton(label: confirmLabel, destructive: true, onPressed: () => close(true))
                  else
                    GradientButton(label: confirmLabel, compact: true, onPressed: () => close(true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

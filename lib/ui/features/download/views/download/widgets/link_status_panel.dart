import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/features/download/providers/link_input/link_input_notifier.dart';

/// Under the link field: what the link is, and the Preview action.
class const LinkStatusPanel({
  super.key,
  required final LinkStatus status,
  required final VoidCallback onPreview,
  final Site? site,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, text, color) = switch (status) {
      .empty => (null, null, colors.textSecondary),
      .notALink => (Symbols.help_rounded, DownloadMessages.notALink, colors.textSecondary),
      .unsupported => (Symbols.block_rounded, DownloadMessages.unsupportedLink, colors.warning),
      .recognised => (Symbols.check_circle_rounded, DownloadMessages.recognised(site!.label), colors.success),
    };

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: .topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const .only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: AppSpacing.md,
                children: [
                  Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Icon(icon, size: 18, color: color, fill: 1),
                      Expanded(
                        child: Text(text, style: context.text.label.copyWith(color: color)),
                      ),
                    ],
                  ),
                  if (status == .recognised)
                    GradientButton(
                      label: DownloadMessages.preview,
                      icon: Symbols.visibility_rounded,
                      expand: true,
                      onPressed: onPreview,
                    ),
                ],
              ),
            ),
    );
  }
}

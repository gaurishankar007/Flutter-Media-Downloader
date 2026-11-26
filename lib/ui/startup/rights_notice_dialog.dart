import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_downloader/ui/core/ui/base/icons/gradient_icon_tile.dart';

/// The one-time notice that users are responsible for what they download.
/// Not dismissible on first launch; dismissible when reopened from Settings.
Future<void> showRightsNoticeDialog(BuildContext context, {bool dismissible = false}) => showDialog<void>(
  context: context,
  barrierDismissible: dismissible,
  barrierColor: context.colors.scrim,
  builder: (context) => PopScope(canPop: dismissible, child: const RightsNoticeDialog()),
);

class const RightsNoticeDialog({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const .all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const .all(AppSpacing.xl),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: AppSpacing.lg,
            children: [
              const GradientIconTile(icon: Symbols.gavel_rounded, size: 52),
              Text(StartupMessages.rightsTitle, style: context.text.title),
              // Scrolls on short screens and at large text sizes; the button stays visible.
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    StartupMessages.rightsBody,
                    style: context.text.body.copyWith(color: context.colors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GradientButton(
                label: StartupMessages.rightsAccept,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

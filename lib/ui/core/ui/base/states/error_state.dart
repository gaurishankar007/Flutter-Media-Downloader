import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/tonal_button.dart';

/// A failure in place of content: icon, message and Retry.
class const ErrorState({
  super.key,
  required final String message,
  final String title = CommonMessages.errorTitle,
  final VoidCallback? onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const .symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: .min,
        spacing: AppSpacing.md,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: .circular(20),
              border: .all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Icon(Symbols.error_rounded, color: colors.error, size: 32, fill: 1),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: context.text.headline, textAlign: .center),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              style: context.text.body.copyWith(color: colors.textSecondary),
              textAlign: .center,
            ),
          ),
          if (onRetry != null)
            Padding(
              padding: const .only(top: AppSpacing.sm),
              child: TonalButton(label: CommonMessages.retry, icon: Symbols.refresh_rounded, onPressed: onRetry),
            ),
        ],
      ),
    );
  }
}

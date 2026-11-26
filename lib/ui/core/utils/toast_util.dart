import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// Shows toasts stacked like notifications, the oldest in front.
/// Views call it; notifiers never do.
abstract final class ToastUtil {
  // The last shown toast, until it closes, to skip a repeat of it.
  static ({String message, Color color})? _lastToast;
  static int _toastId = 0;

  static void show(BuildContext context, String message) =>
      _show(context, message, icon: Symbols.info_rounded, color: context.colors.primary);

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, icon: Symbols.check_circle_rounded, color: context.colors.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, icon: Symbols.error_rounded, color: context.colors.error);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, icon: Symbols.warning_rounded, color: context.colors.warning);

  static void showStateMessage(BuildContext context, StateMessage? message) => switch (message) {
    ErrorMessage(:final text) => showError(context, text),
    SuccessMessage(:final text) => showSuccess(context, text),
    WarningMessage(:final text) => showWarning(context, text),
    NormalMessage(:final text) => show(context, text),
    null => null,
  };

  static void _show(BuildContext context, String message, {required IconData icon, required Color color}) {
    if (_lastToast case (message: final lastMessage, color: final lastColor)
        when lastMessage == message && lastColor == color) {
      return;
    }
    final onColor = context.colors.onPrimary;
    final textStyle = context.text.label.copyWith(color: onColor);
    final width = MediaQuery.sizeOf(context).width;
    final toastId = ++_toastId;
    InteractiveToast.slide(
      context: context,
      displayMode: .stacked,
      leading: Icon(icon, color: onColor, fill: 1),
      title: Text(message, maxLines: 4, overflow: .ellipsis, style: textStyle),
      toastSetting: SlidingToastSetting(
        maxWidth: width < 600 ? width - AppSpacing.screenPhone * 2 : 420,
        maxHeight: 120,
        displayDuration: const Duration(milliseconds: 2500),
        toastStartPosition: .top,
        toastAlignment: .topCenter,
        padding: const .only(top: AppSpacing.xxl),
        showProgressBar: false,
        showPendingCount: false,
      ),
      toastStyle: ToastStyle(
        padding: const .symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        borderRadius: AppRadius.lgAll,
        backgroundColor: color,
        titleLeadingGap: AppSpacing.md,
        expandedTitle: false,
      ),
      onDisposed: () {
        if (toastId == _toastId) {
          _lastToast = null;
        }
      },
    );
    _lastToast = (message: message, color: color);
  }
}

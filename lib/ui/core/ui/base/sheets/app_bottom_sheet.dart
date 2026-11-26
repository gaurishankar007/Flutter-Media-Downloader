import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/layout/pinned_action_bar.dart';

/// Opens [child] in the app's bottom sheet: drag handle, `xl` top corners,
/// scrim, keyboard-aware, scrolls when taller than the screen.
///
/// Pass [ownLayout] when [child] builds its own [AppBottomSheet], e.g. to pin
/// a bottom action that depends on its state.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required Widget child, bool ownLayout = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: context.colors.scrim,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => ownLayout ? child : AppBottomSheet(child: child),
    );

/// The padded, scrollable body of a bottom sheet with an optional [title].
/// A [bottomAction] stays pinned under the scrolling body, above the
/// keyboard and the home indicator.
class const AppBottomSheet({super.key, required final Widget child, final String? title, final Widget? bottomAction})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: .fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  bottomAction == null ? AppSpacing.xl : AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    if (title != null) Text(title!, maxLines: 2, overflow: .ellipsis, style: context.text.title),
                    child,
                  ],
                ),
              ),
            ),
            if (bottomAction != null)
              PinnedActionBar(
                color: context.colors.surface,
                sidePadding: AppSpacing.xl,
                bottomInset: AppSpacing.sm,
                child: bottomAction!,
              ),
          ],
        ),
      ),
    );
  }
}

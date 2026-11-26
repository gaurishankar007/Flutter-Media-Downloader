import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/providers/screen_type/screen_type_notifier.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/layout/pinned_action_bar.dart';

/// A screen's scrolling body: safe area, side padding by breakpoint, content
/// capped at a readable width, and room for the floating nav bar.
///
/// A [bottomAction] (the screen's primary button) is pinned at the bottom,
/// above the nav bar, whatever the content's height; the content scrolls
/// above it.
class const ScreenScrollView({
  super.key,
  required final List<Widget> children,
  final Widget? background,
  final Widget? bottomAction,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenType = ref.watch(screenTypeProvider);
    final sidePadding = screenType == .phone ? AppSpacing.screenPhone : AppSpacing.screenWide;
    // The shell's Scaffold (extendBody) reports the floating nav bar's height
    // as bottom padding; pushed screens report the home indicator.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final scrollView = SingleChildScrollView(
      keyboardDismissBehavior: .onDrag,
      padding: .fromLTRB(
        sidePadding,
        0,
        sidePadding,
        bottomAction == null ? bottomInset + AppSpacing.xl : AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Column(crossAxisAlignment: .stretch, children: children),
        ),
      ),
    );

    return Stack(
      children: [
        ?background,
        SafeArea(
          bottom: false,
          child: bottomAction == null
              ? scrollView
              : Column(
                  children: [
                    Expanded(child: scrollView),
                    PinnedActionBar(
                      color: context.colors.background,
                      sidePadding: sidePadding,
                      bottomInset: bottomInset,
                      child: bottomAction!,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';

/// Holds a screen's or sheet's primary action at the bottom, under its
/// scrolling content (see `ScreenScrollView.bottomAction` and
/// `AppBottomSheet.bottomAction`). A short fade into [color] above the bar
/// shows that the content goes on behind it. [bottomInset] keeps the action
/// above the floating nav bar or the home indicator.
class const PinnedActionBar({
  super.key,
  required final Widget child,
  required final Color color,
  final double sidePadding = AppSpacing.screenPhone,
  final double bottomInset = 0,
}) extends StatelessWidget {
  static const _fadeHeight = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: .none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -_fadeHeight,
          height: _fadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topCenter,
                  end: .bottomCenter,
                  colors: [color.withValues(alpha: 0), color],
                ),
              ),
            ),
          ),
        ),
        ColoredBox(
          color: color,
          child: Padding(
            padding: .fromLTRB(sidePadding, AppSpacing.md, sidePadding, AppSpacing.md + bottomInset),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

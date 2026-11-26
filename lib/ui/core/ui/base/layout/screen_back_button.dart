import 'package:auto_route/auto_route.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';

/// The back arrow at the top of a pushed screen's `ScreenScrollView`.
class const ScreenBackButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .centerLeft,
      child: Padding(
        padding: const .only(top: AppSpacing.sm),
        child: AppIconButton(
          icon: Symbols.arrow_back_rounded,
          label: CommonMessages.back,
          onPressed: () => context.router.maybePop(),
        ),
      ),
    );
  }
}

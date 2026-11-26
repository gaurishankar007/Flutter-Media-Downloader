import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_colors.dart';
import 'package:media_downloader/ui/core/themes/app_typography.dart';

/// Token access from widgets: `context.colors.surface`, `context.text.title`.
extension ThemeTokens on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  AppTypography get text => Theme.of(this).extension<AppTypography>()!;

  bool get isDark => Theme.of(this).brightness == .dark;
}

import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_colors.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/app_typography.dart';

/// Material 3 theme filled from the tokens, so stock widgets (dialogs,
/// switches, sliders) match without extra styling.
ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == .dark ? AppColors.dark : AppColors.light;
  final text = AppTypography.withColor(colors.textPrimary);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.background,
    error: colors.error,
    onError: colors.onPrimary,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    onSurfaceVariant: colors.textSecondary,
    surfaceContainerLowest: colors.background,
    surfaceContainerLow: colors.surface,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceRaised,
    surfaceContainerHighest: colors.surfaceRaised,
    outline: colors.outline,
    outlineVariant: colors.outline,
    scrim: colors.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    fontFamily: AppTypography.interFamily,
    splashFactory: InkSparkle.splashFactory,
    extensions: [colors, text],
    textTheme: TextTheme(
      displaySmall: text.display,
      titleLarge: text.title,
      titleMedium: text.headline,
      bodyLarge: text.body,
      bodyMedium: text.body,
      labelLarge: text.bodyStrong,
      labelMedium: text.label,
      labelSmall: text.caption,
    ),
    dividerTheme: DividerThemeData(color: colors.outline, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      titleTextStyle: text.title,
      contentTextStyle: text.body.copyWith(color: colors.textSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.outline,
      shape: const RoundedRectangleBorder(borderRadius: .vertical(top: .circular(AppRadius.xl))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.onPrimary : colors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.primary : colors.surfaceRaised,
      ),
      trackOutlineColor: WidgetStatePropertyAll(colors.outline),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primaryText,
      selectionColor: colors.primary.withValues(alpha: 0.35),
      selectionHandleColor: colors.primaryText,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: AppRadius.smAll),
      textStyle: text.caption,
    ),
  );
}

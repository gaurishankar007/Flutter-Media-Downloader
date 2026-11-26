import 'package:material_ui/material_ui.dart';

/// Colour tokens for both themes. Widgets read them through `context.colors`;
/// never write a hex value in a widget. See docs/design/design_system.md#colour.
final class const AppColors({
  required final Color background,
  required final Color surface,
  required final Color surfaceRaised,
  required final Color outline,
  required final Color textPrimary,
  required final Color textSecondary,
  required final Color textMuted,
  required final Color primary,
  required final Color onPrimary,
  required final Color primaryText,
  required final Color secondary,
  required final Color success,
  required final Color warning,
  required final Color error,
  required final Color scrim,
}) extends ThemeExtension<AppColors> {
  static const dark = AppColors(
    background: Color(0xFF0B0B12),
    surface: Color(0xFF14141F),
    surfaceRaised: Color(0xFF1C1C2A),
    outline: Color(0xFF2A2A3C),
    textPrimary: Color(0xFFF5F5FA),
    textSecondary: Color(0xFFA1A1B5),
    textMuted: Color(0xFF6B6B80),
    primary: Color(0xFF6A4CF5),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF8B73FF),
    secondary: Color(0xFF22D3EE),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF5A524),
    error: Color(0xFFF43F5E),
    scrim: Color(0x99000000),
  );

  static const light = AppColors(
    background: Color(0xFFF7F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F0F7),
    outline: Color(0xFFE2E2EC),
    textPrimary: Color(0xFF0F0F1A),
    textSecondary: Color(0xFF5B5B70),
    textMuted: Color(0xFF8E8EA3),
    primary: Color(0xFF6A4CF5),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF5A3DE6),
    secondary: Color(0xFF0891B2),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFE11D48),
    scrim: Color(0x660F0F1A),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      outline: mix(outline, other.outline),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryText: mix(primaryText, other.primaryText),
      secondary: mix(secondary, other.secondary),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      scrim: mix(scrim, other.scrim),
    );
  }
}

/// Colours that don't change with the theme because they sit on photos and
/// video frames (pills, checks), plus the sites' badge colours.
abstract final class MediaColors {
  /// Behind text on a thumbnail (duration pill).
  static const overlay = Color(0xB3000000);

  /// Behind an unselected check on a photo.
  static const overlaySoft = Color(0x66000000);

  /// Text and icons on [overlay] or a gradient.
  static const onOverlay = Color(0xFFFFFFFF);
}

/// Site badge colours. See docs/design/design_system.md#site-colours.
abstract final class SiteColors {
  static const youtube = Color(0xFFFF0033);
  static const facebook = Color(0xFF0866FF);
  static const tiktokGlyph = Color(0xFF25F4EE);
}

import 'package:material_ui/material_ui.dart';

/// Type scale: Plus Jakarta Sans for display and headings, Inter for the rest.
/// See docs/design/design_system.md#typography.
final class const AppTypography({
  required final TextStyle display,

  /// A tab or pushed screen's header title (between display and title).
  required final TextStyle screenTitle,
  required final TextStyle title,
  required final TextStyle headline,
  required final TextStyle body,
  required final TextStyle bodyStrong,
  required final TextStyle label,
  required final TextStyle caption,

  /// Live numbers (percent, speed, sizes): tabular figures so digits don't jump.
  required final TextStyle numeric,
}) extends ThemeExtension<AppTypography> {
  factory withColor(Color color) => AppTypography(
    display: _jakarta.copyWith(fontSize: 32, height: 40 / 32, fontWeight: .w800, letterSpacing: -0.6, color: color),
    screenTitle: _jakarta.copyWith(fontSize: 28, height: 34 / 28, fontWeight: .w700, letterSpacing: -0.4, color: color),
    title: _jakarta.copyWith(fontSize: 22, height: 28 / 22, fontWeight: .w700, letterSpacing: -0.3, color: color),
    headline: _jakarta.copyWith(fontSize: 18, height: 24 / 18, fontWeight: .w700, letterSpacing: -0.2, color: color),
    body: _inter.copyWith(fontSize: 15, height: 22 / 15, fontWeight: .w400, color: color),
    bodyStrong: _inter.copyWith(fontSize: 15, height: 22 / 15, fontWeight: .w600, color: color),
    label: _inter.copyWith(fontSize: 13, height: 18 / 13, fontWeight: .w500, color: color),
    caption: _inter.copyWith(fontSize: 12, height: 16 / 12, fontWeight: .w500, color: color),
    numeric: _inter.copyWith(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: .w600,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  static const jakartaFamily = 'PlusJakartaSans';
  static const interFamily = 'Inter';
  static const _jakarta = TextStyle(fontFamily: jakartaFamily);
  static const _inter = TextStyle(fontFamily: interFamily);

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) {
      return this;
    }
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      display: mix(display, other.display),
      screenTitle: mix(screenTitle, other.screenTitle),
      title: mix(title, other.title),
      headline: mix(headline, other.headline),
      body: mix(body, other.body),
      bodyStrong: mix(bodyStrong, other.bodyStrong),
      label: mix(label, other.label),
      caption: mix(caption, other.caption),
      numeric: mix(numeric, other.numeric),
    );
  }
}

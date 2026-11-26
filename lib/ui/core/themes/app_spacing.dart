import 'package:material_ui/material_ui.dart';

/// 4pt spacing grid. See docs/design/design_system.md#spacing-radius-and-elevation.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Gap between a screen's sections when there's no section title to
  /// space them (a section title carries this gap above itself).
  static const double section = xl;

  /// Side padding of a screen on phones and on wider layouts.
  static const double screenPhone = 16;
  static const double screenWide = 24;

  /// Widest a screen's content gets on macOS / tablets, so lines stay readable.
  static const double maxContentWidth = 760;
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const BorderRadius smAll = .all(.circular(sm));
  static const BorderRadius mdAll = .all(.circular(md));
  static const BorderRadius lgAll = .all(.circular(lg));
  static const BorderRadius xlAll = .all(.circular(xl));
  static const BorderRadius pill = .all(.circular(999));
}

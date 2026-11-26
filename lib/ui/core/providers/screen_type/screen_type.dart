/// Layout breakpoints. See docs/design/design_system.md#layout-and-navigation.
enum ScreenType {
  /// < 600: bottom nav, one column.
  phone,

  /// 600–839: bottom nav, two-column grids.
  tablet,

  /// ≥ 840 (tablets, macOS): sidebar, two panes.
  desktop;

  factory fromWidth(double width) => switch (width) {
    < 600 => phone,
    < 840 => tablet,
    _ => desktop,
  };

  bool get usesSidebar => this == desktop;
}

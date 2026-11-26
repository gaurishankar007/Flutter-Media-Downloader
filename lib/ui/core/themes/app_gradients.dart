import 'package:material_ui/material_ui.dart';

/// Gradients. Aurora marks the one primary action on a screen, progress and
/// the active tab, never a full background. See docs/design/design_system.md#brand-gradient-aurora.
abstract final class AppGradients {
  static const auroraColors = [Color(0xFF6A4CF5), Color(0xFFB44CF0), Color(0xFFFF4D8D)];

  static const aurora = LinearGradient(begin: .topLeft, end: .bottomRight, colors: auroraColors);

  static const instagram = LinearGradient(
    begin: .bottomLeft,
    end: .topRight,
    colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
  );
}

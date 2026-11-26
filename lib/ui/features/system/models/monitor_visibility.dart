import 'package:material_ui/material_ui.dart';

/// Whether the app is on screen. `inactive` still counts: a macOS window
/// without focus, or iOS during a call banner, is still visible.
bool isAppVisible(AppLifecycleState? state) => switch (state) {
  null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
  _ => false,
};

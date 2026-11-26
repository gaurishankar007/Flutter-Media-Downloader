import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';

/// The five tabs, in order. Index matches the AutoTabsRouter routes.
enum NavDestination {
  download(Symbols.download_rounded, NavMessages.download),
  library(Symbols.video_library_rounded, NavMessages.library),
  convert(Symbols.swap_horiz_rounded, NavMessages.convert),
  system(Symbols.monitoring_rounded, NavMessages.system),
  settings(Symbols.settings_rounded, NavMessages.settings);

  new(this.icon, this.label);

  final IconData icon;
  final String label;
}

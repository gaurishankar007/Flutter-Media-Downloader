import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/themes/app_colors.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/app_typography.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A small rounded square in the site's colour with a generic glyph (not the
/// site's logo). Only the badge uses the site colour.
class const SiteBadge({super.key, required final Site site, final double size = 20}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inverted = context.isDark && (site == .x || site == .threads);
    final background = switch (site) {
      .youtube => SiteColors.youtube,
      .facebook => SiteColors.facebook,
      .x || .threads => inverted ? Colors.white : Colors.black,
      .tiktok => Colors.black,
      .instagram => null,
    };
    final glyphColor = switch (site) {
      .tiktok => SiteColors.tiktokGlyph,
      .x || .threads => inverted ? Colors.black : Colors.white,
      _ => Colors.white,
    };
    final glyph = switch (site) {
      .youtube => _iconGlyph(Symbols.play_arrow_rounded, glyphColor),
      .instagram => _iconGlyph(Symbols.photo_camera_rounded, glyphColor),
      .tiktok => _iconGlyph(Symbols.music_note_rounded, glyphColor),
      .facebook => _letterGlyph('f', glyphColor),
      .x => _letterGlyph('X', glyphColor),
      .threads => _letterGlyph('@', glyphColor),
    };

    return Semantics(
      label: site.label,
      child: Container(
        width: size,
        height: size,
        alignment: .center,
        decoration: BoxDecoration(
          color: background,
          gradient: site == .instagram ? AppGradients.instagram : null,
          borderRadius: .circular(size * 0.3),
        ),
        child: glyph,
      ),
    );
  }

  Widget _iconGlyph(IconData icon, Color color) => Icon(icon, size: size * 0.7, color: color, fill: 1);

  Widget _letterGlyph(String letter, Color color) => Text(
    letter,
    style: TextStyle(
      fontFamily: AppTypography.jakartaFamily,
      fontWeight: .w800,
      fontSize: size * 0.62,
      height: 1,
      color: color,
    ),
  );
}

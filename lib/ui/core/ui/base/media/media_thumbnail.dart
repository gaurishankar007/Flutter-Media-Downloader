import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/ui/core/themes/app_colors.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A rounded thumbnail for a local or remote image, with an optional
/// duration pill and a saved check. Falls back to the kind's icon when there
/// is no image or it fails to load.
class const MediaThumbnail({
  super.key,
  required final MediaKind kind,
  final ImageProvider? image,
  final String? duration,
  final bool saved = false,
  final double aspectRatio = 16 / 9,
  final BorderRadius borderRadius = AppRadius.mdAll,
  final Object? heroTag,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = ColoredBox(
      color: colors.surfaceRaised,
      child: Center(
        child: Icon(switch (kind) {
          .video => Symbols.movie_rounded,
          .audio => Symbols.music_note_rounded,
          .photo => Symbols.image_rounded,
          .document => Symbols.picture_as_pdf_rounded,
        }, color: colors.textMuted),
      ),
    );

    final content = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: .expand,
          children: [
            if (image case final image?)
              Image(
                image: image,
                fit: .cover,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, loaded) => loaded || frame != null ? child : placeholder,
              )
            else
              placeholder,
            if (duration != null)
              Positioned(
                right: AppSpacing.xs + 2,
                bottom: AppSpacing.xs + 2,
                child: Container(
                  padding: const .symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                  decoration: const BoxDecoration(color: MediaColors.overlay, borderRadius: AppRadius.smAll),
                  child: Text(duration!, style: context.text.caption.copyWith(color: MediaColors.onOverlay)),
                ),
              ),
            if (saved)
              Positioned(
                right: AppSpacing.xs + 2,
                top: AppSpacing.xs + 2,
                child: Container(
                  padding: const .all(3),
                  decoration: BoxDecoration(color: colors.success, shape: .circle),
                  child: const Icon(Symbols.check_rounded, size: 12, color: Colors.white, weight: 700),
                ),
              ),
          ],
        ),
      ),
    );

    return heroTag == null ? content : Hero(tag: heroTag!, child: content);
  }
}

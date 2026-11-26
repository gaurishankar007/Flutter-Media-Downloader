import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/ui/core/themes/app_colors.dart';
import 'package:media_downloader/ui/core/themes/app_gradients.dart';
import 'package:media_downloader/ui/core/themes/app_motion.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/media/media_thumbnail.dart';

/// The photos of a post, selectable. Selected tiles get an Aurora ring and a
/// numbered check. Sizes itself to its content (sits inside a scroll view).
class const PhotoGrid({
  super.key,
  required final List<ImageProvider?> photos,
  required final Set<int> selected,
  required final ValueChanged<int> onToggle,
  final int columns = 3,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: .zero,
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final isSelected = selected.contains(index);
        return Semantics(
          selected: isSelected,
          button: true,
          child: GestureDetector(
            onTap: () => onToggle(index),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const .all(2.5),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.aurora : null,
                color: isSelected ? null : colors.outline,
                borderRadius: AppRadius.mdAll,
              ),
              child: Stack(
                fit: .expand,
                children: [
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: isSelected ? 1 : 0.55,
                    child: MediaThumbnail(
                      kind: MediaKind.photo,
                      image: photos[index],
                      aspectRatio: 1,
                      borderRadius: const .all(.circular(AppRadius.md - 2.5)),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.xs + 2,
                    right: AppSpacing.xs + 2,
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      width: 22,
                      height: 22,
                      alignment: .center,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.aurora : null,
                        color: isSelected ? null : MediaColors.overlaySoft,
                        shape: .circle,
                        border: .all(color: Colors.white, width: 1.5),
                      ),
                      child: isSelected
                          ? const Icon(Symbols.check_rounded, size: 14, color: Colors.white, weight: 700)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

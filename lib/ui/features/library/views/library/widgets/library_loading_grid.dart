import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/states/shimmer_box.dart';

/// Shimmer cards in the Library grid's layout while the Library loads.
class const LibraryLoadingGrid({super.key}) extends StatelessWidget {
  static const _minCardWidth = 168.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minCardWidth).floor().clamp(2, 5);
        final cardWidth = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var index = 0; index < columns * 2; index++)
              Padding(
                padding: const .all(AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppSpacing.sm,
                  children: [
                    ShimmerBox(
                      width: cardWidth - AppSpacing.xs * 2,
                      height: (cardWidth - AppSpacing.xs * 2) * 9 / 16,
                      borderRadius: AppRadius.lgAll,
                    ),
                    ShimmerBox(width: cardWidth * 0.8, height: AppSpacing.md),
                    ShimmerBox(width: cardWidth * 0.5, height: AppSpacing.md),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

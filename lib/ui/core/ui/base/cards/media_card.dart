import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/media/media_thumbnail.dart';
import 'package:media_tool/ui/core/ui/base/media/site_badge.dart';

/// A Library grid item: thumbnail, two-line title, site badge and metadata.
/// Long-press or right-click calls [onMore] (the action sheet). A non-null
/// [selected] shows a selection check (multi-select mode). A [count] above 1
/// marks a grouped post (stack icon + number).
class const MediaCard({
  super.key,
  required final String title,
  required final MediaKind kind,
  final String? metadata,
  final ImageProvider? image,
  final String? duration,
  final Site? site,
  final bool saved = false,
  final Object? heroTag,
  final bool? selected,
  final int? count,
  final VoidCallback? onTap,
  final VoidCallback? onMore,
}) extends StatelessWidget {
  /// The card's height at [width]: a 16:9 thumbnail plus two title lines and
  /// the metadata line at the current text size. Grids use it as their
  /// `mainAxisExtent` so long titles and large text never overflow.
  static double heightFor(BuildContext context, double width) {
    final text = context.text;
    final scaler = MediaQuery.textScalerOf(context);
    final thumbnail = (width - AppSpacing.xs * 2) * 9 / 16;
    final title = scaler.scale(text.bodyStrong.fontSize!) * 1.3 * 2;
    final metadata = scaler.scale(text.caption.fontSize! * text.caption.height!);
    return AppSpacing.xs * 2 + thumbnail + AppSpacing.sm * 2 + title + metadata + AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onLongPress: onMore,
      onSecondaryTap: onMore,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const .all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: .start,
            spacing: AppSpacing.sm,
            children: [
              Stack(
                children: [
                  MediaThumbnail(
                    kind: kind,
                    image: image,
                    duration: duration,
                    saved: saved,
                    heroTag: heroTag,
                    borderRadius: AppRadius.lgAll,
                  ),
                  if (count case final count? when count > 1)
                    Positioned(
                      left: AppSpacing.xs + 2,
                      bottom: AppSpacing.xs + 2,
                      child: Semantics(
                        label: LibraryMessages.groupCount(count),
                        child: Container(
                          padding: const .symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                          decoration: BoxDecoration(color: colors.scrim, borderRadius: AppRadius.smAll),
                          child: Row(
                            mainAxisSize: .min,
                            spacing: 3,
                            children: [
                              Icon(Symbols.photo_library_rounded, size: 12, color: colors.onPrimary, fill: 1),
                              Text('$count', style: context.text.caption.copyWith(color: colors.onPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (selected case final isSelected?) ...[
                    if (isSelected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.lgAll,
                            border: .all(color: colors.primary, width: 3),
                            color: colors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: Icon(
                        isSelected ? Symbols.check_circle_rounded : Symbols.radio_button_unchecked_rounded,
                        fill: isSelected ? 1 : 0,
                        color: isSelected ? colors.primary : colors.onPrimary,
                        size: 26,
                      ),
                    ),
                  ],
                ],
              ),
              Text(title, maxLines: 2, overflow: .ellipsis, style: context.text.bodyStrong.copyWith(height: 1.3)),
              Row(
                spacing: AppSpacing.xs + 2,
                children: [
                  if (site != null) SiteBadge(site: site!, size: 16),
                  if (metadata != null)
                    Expanded(
                      child: Text(
                        metadata!,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: context.text.caption.copyWith(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

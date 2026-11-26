import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/cards/media_card.dart';
import 'package:media_downloader/ui/core/utils/local_media.dart';
import 'package:media_downloader/ui/features/library/providers/library/library_notifier.dart';

/// A Library grid to pick the converter's input from. Pops with the item id.
class const LibraryPickerSheet({super.key}) extends ConsumerWidget {
  static const _minCardWidth = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(libraryProvider.select((state) => state.entries));
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.lg,
      children: [
        Text(ConvertMessages.pickFromLibrary, style: context.text.title),
        if (entries.isEmpty)
          Text(ConvertMessages.libraryEmpty, style: context.text.body.copyWith(color: context.colors.textSecondary))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / _minCardWidth).floor().clamp(2, 4);
              final cardWidth = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: .zero,
                itemCount: entries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: MediaCard.heightFor(context, cardWidth),
                ),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final item = entry.item;
                  return MediaCard(
                    key: ValueKey(entry.id),
                    title: item.title,
                    kind: item.kind,
                    site: item.site,
                    image: entry.thumbnailPath == null ? null : LocalMedia.image(entry.thumbnailPath!),
                    duration: item.durationMs == null ? null : FormatUtils.duration(item.durationMs! ~/ 1000),
                    metadata: [FormatUtils.bytes(item.sizeBytes), item.format.toUpperCase()].join(' · '),
                    onTap: () => Navigator.of(context).pop(entry.id),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

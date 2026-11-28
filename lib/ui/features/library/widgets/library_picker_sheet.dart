import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/media_card.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:media_tool/ui/features/library/providers/library/library_notifier.dart';

/// A Library grid to pick inputs from (Convert, Tools), limited to [kinds] and
/// [formats] (lower-case extensions) when given. Pops with the picked ids: one
/// on tap, or several in tap order with Add when [multiple].
class const LibraryPickerSheet({
  super.key,
  final Set<MediaKind>? kinds,
  final Set<String>? formats,
  final bool multiple = false,
  final String emptyText = ConvertMessages.libraryEmpty,
}) extends HookConsumerWidget {
  static const _minCardWidth = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(libraryProvider.select((state) => state.entries));
    final entries = [
      for (final entry in all)
        if ((kinds?.contains(entry.item.kind) ?? true) && (formats?.contains(entry.item.format.toLowerCase()) ?? true))
          entry,
    ];
    final picked = useState(<String>[]);

    void toggle(String id) => picked.value = picked.value.contains(id)
        ? [...picked.value.where((other) => other != id)]
        : [...picked.value, id];

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.lg,
      children: [
        Text(ConvertMessages.pickFromLibrary, style: context.text.title),
        if (entries.isEmpty)
          Text(emptyText, style: context.text.body.copyWith(color: context.colors.textSecondary))
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
                    selected: multiple ? picked.value.contains(entry.id) : null,
                    onTap: multiple ? () => toggle(entry.id) : () => Navigator.of(context).pop([entry.id]),
                  );
                },
              );
            },
          ),
        if (multiple && entries.isNotEmpty)
          GradientButton(
            label: ToolsMessages.addPicked(picked.value.length),
            icon: Symbols.add_rounded,
            expand: true,
            onPressed: picked.value.isEmpty ? null : () => Navigator.of(context).pop(picked.value),
          ),
      ],
    );
  }
}

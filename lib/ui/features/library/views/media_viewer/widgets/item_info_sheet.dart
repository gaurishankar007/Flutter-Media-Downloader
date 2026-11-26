import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/features/library/models/library_entry.dart';
import 'package:path/path.dart' as p;

/// Source URL, size, format, duration, date and file name of an item.
class const ItemInfoSheet({super.key, required final LibraryEntry entry}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final rows = [
      (LibraryMessages.infoFile, p.basename(entry.filePath)),
      (LibraryMessages.infoSize, FormatUtils.bytes(item.sizeBytes)),
      (LibraryMessages.infoFormat, item.format.toUpperCase()),
      if (item.durationMs case final duration?) (LibraryMessages.infoDuration, FormatUtils.duration(duration ~/ 1000)),
      (LibraryMessages.infoAdded, DateFormat.yMMMd().add_jm().format(item.createdAt)),
      if (item.sourceUrl case final url?) (LibraryMessages.infoSource, url),
    ];

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        Text(item.title, maxLines: 3, overflow: .ellipsis, style: context.text.headline),
        for (final (label, value) in rows)
          Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(label, style: context.text.caption.copyWith(color: context.colors.textSecondary)),
              SelectableText(value, style: context.text.body),
            ],
          ),
      ],
    );
  }
}

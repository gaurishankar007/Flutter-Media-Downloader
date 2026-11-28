import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/media/site_badge.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';

/// The post's title, where it came from, how many items and their size.
class const PostHeader({super.key, required final List<LibraryEntry> members}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final first = members.first.item;
    final bytes = members.fold(0, (total, entry) => total + entry.item.sizeBytes);
    final source = [?first.site?.label, ?first.uploader].join(' · ');
    final secondary = context.text.label.copyWith(color: context.colors.textSecondary);
    return Padding(
      padding: const .only(top: AppSpacing.lg, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs + 2,
        children: [
          Text(first.title, maxLines: 3, overflow: .ellipsis, style: context.text.screenTitle),
          if (source.isNotEmpty)
            Row(
              spacing: AppSpacing.sm,
              children: [
                if (first.site case final site?) SiteBadge(site: site, size: 18),
                Flexible(
                  child: Text(source, maxLines: 1, overflow: .ellipsis, style: secondary),
                ),
              ],
            ),
          Text(
            [
              LibraryMessages.summary(members.length, FormatUtils.bytes(bytes)),
              DateFormat.yMMMd().format(first.createdAt),
            ].join(' · '),
            style: secondary,
          ),
        ],
      ),
    );
  }
}

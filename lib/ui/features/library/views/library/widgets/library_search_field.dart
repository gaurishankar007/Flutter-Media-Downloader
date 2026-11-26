import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// Search by title or uploader.
class const LibrarySearchField({super.key, required final ValueChanged<String> onChanged}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 44,
      padding: const .symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.pill,
        border: .all(color: colors.outline),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Icon(Symbols.search_rounded, size: 20, color: colors.textMuted),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textInputAction: .search,
              style: context.text.body,
              decoration: InputDecoration(
                hintText: LibraryMessages.searchHint,
                hintStyle: context.text.body.copyWith(color: colors.textMuted),
                border: .none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

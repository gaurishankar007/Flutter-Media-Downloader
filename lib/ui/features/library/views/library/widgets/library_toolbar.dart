import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_tool/ui/features/library/views/library/widgets/library_search_field.dart';
import 'package:media_tool/ui/features/library/views/library/widgets/sort_menu.dart';

/// Search, sort and Select / Done.
class const LibraryToolbar({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(libraryProvider.notifier);
    final sort = ref.watch(libraryProvider.select((state) => state.filter.sort));
    final selecting = ref.watch(libraryProvider.select((state) => state.selecting));

    return Row(
      spacing: AppSpacing.sm,
      children: [
        Expanded(child: LibrarySearchField(onChanged: notifier.search)),
        SortMenu(selected: sort, onSelected: notifier.setSort),
        GhostButton(
          label: selecting ? LibraryMessages.done : LibraryMessages.select,
          onPressed: selecting ? notifier.stopSelecting : notifier.startSelecting,
        ),
      ],
    );
  }
}

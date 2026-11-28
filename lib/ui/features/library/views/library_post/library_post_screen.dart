import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_back_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_tool/ui/features/library/views/library_post/widgets/post_actions.dart';
import 'package:media_tool/ui/features/library/views/library_post/widgets/post_header.dart';
import 'package:media_tool/ui/features/library/views/library_post/widgets/post_item_grid.dart';
import 'package:media_tool/ui/features/library/widgets/library_actions_listener.dart';

/// One grouped post (a carousel download, or a tool's several outputs): its
/// details, actions for every item, and a grid of the items. Closes once
/// they're all deleted. See docs/features/library.md#post-page.
@RoutePage()
class const LibraryPostScreen({super.key, required final String groupId}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(libraryProvider.select((state) => state.group(groupId)));

    ref.listen(libraryProvider.select((state) => state.group(groupId).isEmpty), (_, empty) {
      if (empty && context.mounted) {
        context.router.maybePop();
      }
    });

    return LibraryActionsListener(
      child: Scaffold(
        body: ScreenScrollView(
          children: [
            const ScreenBackButton(),
            if (members.isNotEmpty) ...[
              PostHeader(members: members),
              PostActions(members: members),
              const SectionHeader(title: LibraryMessages.postItems),
              PostItemGrid(members: members),
            ],
          ],
        ),
      ),
    );
  }
}

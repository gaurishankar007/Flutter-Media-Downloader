import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_tool/ui/features/library/providers/media_viewer/media_viewer_notifier.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/audio_viewer.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/document_viewer.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/photo_viewer.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/video_viewer.dart';
import 'package:media_tool/ui/features/library/views/media_viewer/widgets/viewer_action_bar.dart';
import 'package:media_tool/ui/features/library/widgets/library_actions_listener.dart';

/// Full-screen viewer for Library items, swiping through [ids].
/// See docs/features/library.md#viewer.
@RoutePage()
class const MediaViewerScreen({super.key, required final String initialId, required final List<String> ids})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mediaViewerProvider.notifier);
    final viewer = ref.watch(mediaViewerProvider);
    final library = ref.watch(libraryProvider);
    final pageController = usePageController(initialPage: ids.contains(initialId) ? ids.indexOf(initialId) : 0);

    useEffect(() {
      // After the first frame: providers can't change during build.
      Future.microtask(() => notifier.open(initialId, ids));
      return null;
    }, const []);

    // Deleted items leave the pager; the viewer closes when none are left.
    ref.listen(libraryProvider.select((state) => {for (final entry in state.entries) entry.id}), (_, existing) {
      notifier.retain(existing);
      if (ref.read(mediaViewerProvider).ids.isEmpty && context.mounted) {
        context.router.maybePop();
      }
    });

    final entries = [for (final id in viewer.ids) ?library.byId(id)];
    final current = viewer.currentId == null ? null : library.byId(viewer.currentId!);

    return LibraryActionsListener(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const .symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    AppIconButton(
                      icon: Symbols.close_rounded,
                      label: CommonMessages.close,
                      onPressed: () => context.router.maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        current?.item.title ?? '',
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: context.text.bodyStrong,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const SizedBox.shrink()
                    : PageView.builder(
                        controller: pageController,
                        itemCount: entries.length,
                        onPageChanged: notifier.show,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final active = index == viewer.index;
                          return switch (entry.item.kind) {
                            .video => VideoViewer(key: ValueKey(entry.id), entry: entry, active: active),
                            .audio => AudioViewer(key: ValueKey(entry.id), entry: entry, active: active),
                            .photo => PhotoViewer(key: ValueKey(entry.id), entry: entry),
                            .document => DocumentViewer(key: ValueKey(entry.id), entry: entry),
                          };
                        },
                      ),
              ),
              if (current != null) ViewerActionBar(entry: current),
            ],
          ),
        ),
      ),
    );
  }
}

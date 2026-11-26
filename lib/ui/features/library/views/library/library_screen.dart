import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_downloader/ui/core/ui/base/states/empty_state.dart';
import 'package:media_downloader/ui/core/ui/base/states/error_state.dart';
import 'package:media_downloader/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_downloader/ui/features/home/models/nav_destination.dart';
import 'package:media_downloader/ui/features/library/providers/library/library_notifier.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/library_filter_bar.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/library_grid.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/library_loading_grid.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/library_toolbar.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/selection_bar.dart';
import 'package:media_downloader/ui/features/library/views/library/widgets/storage_summary.dart';
import 'package:media_downloader/ui/features/library/widgets/library_actions_listener.dart';

/// Everything downloaded or converted. See docs/features/library.md.
@RoutePage()
class const LibraryScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    ref.listenMessages(libraryProvider, context);

    final visible = state.visible;
    final isEmpty = state.status == .loaded && state.entries.isEmpty;
    final noEntries = state.entries.isEmpty;

    return LibraryActionsListener(
      child: ScreenScrollView(
        children: [
          const ScreenHeader(title: LibraryMessages.title, subtitle: LibraryMessages.subtitle),
          if (state.status == .loading && noEntries)
            const LibraryLoadingGrid()
          else if (state.status == .error && noEntries)
            const AppCard(child: ErrorState(message: LibraryMessages.loadFailed))
          else if (isEmpty)
            AppCard(
              child: EmptyState(
                icon: Symbols.video_library_rounded,
                title: LibraryMessages.emptyTitle,
                body: LibraryMessages.emptyBody,
                action: TonalButton(
                  label: LibraryMessages.goToDownload,
                  icon: Symbols.download_rounded,
                  onPressed: () => context.tabsRouter.setActiveIndex(NavDestination.download.index),
                ),
              ),
            )
          else ...[
            StorageSummary(count: state.entries.length, bytes: state.totalBytes),
            const SizedBox(height: AppSpacing.md),
            const LibraryToolbar(),
            const SizedBox(height: AppSpacing.md),
            LibraryFilterBar(
              selected: state.filter.kind,
              onSelected: notifier.setKind,
              sites: state.sites,
              selectedSites: state.filter.sites,
              onSiteToggled: notifier.toggleSite,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.selecting) ...[const SelectionBar(), const SizedBox(height: AppSpacing.md)],
            if (visible.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Symbols.search_off_rounded,
                  title: LibraryMessages.noMatchesTitle,
                  body: LibraryMessages.noMatchesBody,
                ),
              )
            else
              LibraryGrid(entries: visible),
          ],
        ],
      ),
    );
  }
}

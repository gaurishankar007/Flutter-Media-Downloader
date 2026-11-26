import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:media_tool/ui/features/library/models/library_filter.dart';
import 'package:media_tool/ui/features/library/models/library_kind_filter.dart';
import 'package:media_tool/ui/features/library/models/library_sort.dart';

part 'library_state.dart';

/// The live Library list, its filter and multi-select. Keep-alive, so the
/// filter survives tab switches. See docs/features/library.md.
class LibraryNotifier extends BaseNotifier<LibraryState> {
  late final LibraryRepository _repository;

  @override
  LibraryState build() {
    _repository = GetIt.I<LibraryRepository>();
    final subscription = _repository.watchItems().listen(_onItems);
    ref.onDispose(subscription.cancel);
    return const LibraryState(status: .loading);
  }

  void setKind(LibraryKindFilter kind) => state = state.copyWith(filter: state.filter.copyWith(kind: kind));

  void toggleSite(Site site) {
    final sites = {...state.filter.sites};
    if (!sites.remove(site)) {
      sites.add(site);
    }
    state = state.copyWith(filter: state.filter.copyWith(sites: sites));
  }

  void search(String query) => state = state.copyWith(filter: state.filter.copyWith(query: query));

  void setSort(LibrarySort sort) => state = state.copyWith(filter: state.filter.copyWith(sort: sort));

  void startSelecting() => state = state.copyWith(selecting: true, selectedIds: const {});

  void stopSelecting() => state = state.copyWith(selecting: false, selectedIds: const {});

  void toggleSelected(String id) => toggleSelectedAll([id]);

  /// A grouped post card selects or unselects all of its items together.
  void toggleSelectedAll(List<String> ids) {
    final selected = {...state.selectedIds};
    if (selected.containsAll(ids)) {
      selected.removeAll(ids);
    } else {
      selected.addAll(ids);
    }
    state = state.copyWith(selecting: true, selectedIds: selected);
  }

  /// Selects every visible item, or none when all are selected.
  void toggleSelectAll() {
    final visible = {for (final entry in state.visibleItems) entry.id};
    final allSelected = visible.isNotEmpty && state.selectedIds.containsAll(visible);
    state = state.copyWith(selectedIds: allSelected ? const {} : visible);
  }

  void _onItems(DataState<List<LibraryItem>> result) => runFlow('library.watch', () {
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(:final data?):
        final entries = [for (final item in data) _toEntry(item)];
        final ids = {for (final entry in entries) entry.id};
        state = state.copyWith(
          entries: entries,
          status: .loaded,
          // Deleted items drop out of the selection.
          selectedIds: state.selectedIds.intersection(ids),
        );
      default:
        state = state.copyWith(status: .error, message: trackFailure(result));
    }
  });

  LibraryEntry _toEntry(LibraryItem item) => LibraryEntry(
    item: item,
    filePath: _repository.absolutePath(item.relativePath),
    thumbnailPath: item.thumbnailRelativePath == null ? null : _repository.absolutePath(item.thumbnailRelativePath!),
    canSaveToPhotos: _repository.canSaveToPhotos(item.kind),
  );
}

final libraryProvider = NotifierProvider(LibraryNotifier.new);

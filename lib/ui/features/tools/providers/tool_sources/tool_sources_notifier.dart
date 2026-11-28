import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/pick_source.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:media_tool/domain/repositories/tool_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';

part 'tool_sources_state.dart';

/// The files picked for one [tool], in the user's order, and (Organize pages)
/// the PDF's page thumbnails. Keep-alive per tool, so picks survive leaving
/// the screen. See docs/features/tools.md#providers.
class ToolSourcesNotifier(final Tool tool) extends BaseNotifier<ToolSourcesState> {
  late final ToolRepository _repository;

  /// Ids in the Library's latest emission; `null` until the first one.
  Set<String>? _libraryIds;

  @override
  ToolSourcesState build() {
    _repository = GetIt.I<ToolRepository>();
    final libraryItems = GetIt.I<LibraryRepository>().watchItems().listen(_onLibraryItems);
    ref.onDispose(libraryItems.cancel);
    return const ToolSourcesState();
  }

  Future<void> pick(PickSource from) =>
      runFlow('tools.pick', () => _add(() => _repository.pick(tool.input, from: from, multiple: tool.multiple)));

  Future<void> pickFromLibrary(List<String> ids) =>
      runFlow('tools.pickFromLibrary', () => _add(() => _repository.fromLibrary(ids)));

  void remove(int index) => runFlow('tools.removeSource', () {
    if (index < 0 || index >= state.sources.length) {
      return;
    }
    final removed = state.sources[index];
    state = state.copyWith(sources: [...state.sources]..removeAt(index), pageThumbnails: const []);
    _repository.discard([removed]);
  });

  /// Moves the source at [from] so it ends up at [to].
  void reorder(int from, int to) => runFlow('tools.reorderSources', () {
    final sources = [...state.sources];
    sources.insert(to, sources.removeAt(from));
    state = state.copyWith(sources: sources);
  });

  /// Forgets every pick and deletes the working copies.
  Future<void> clear() => runFlow('tools.clearSources', () async {
    final sources = state.sources;
    state = const ToolSourcesState();
    await _repository.discard(sources);
  });

  Future<void> _add(FutureList<LocalMediaInfo> Function() read) async {
    if (state.isReading) {
      return;
    }
    final previous = state.sources;
    state = state.copyWith(status: .loading);
    final result = await read();
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(:final data?) when data.isNotEmpty:
        // Single-file tools replace the pick; others add to the end.
        final sources = tool.multiple ? [...previous, ...data] : [data.first];
        state = ToolSourcesState(sources: sources, status: .loaded);
        if (!tool.multiple && previous.isNotEmpty) {
          await _repository.discard(previous);
        }
        await _loadPages();
      case SuccessState():
        // Cancelled the picker.
        state = state.copyWith(status: previous.isEmpty ? .idle : .loaded);
      default:
        state = state.copyWith(status: previous.isEmpty ? .idle : .loaded, message: trackFailure(result));
    }
  }

  /// Organize pages shows every page; nothing else needs them.
  Future<void> _loadPages() async {
    final source = state.sources.firstOrNull;
    if (tool != .organizePdf || source == null || source.encrypted) {
      return;
    }
    state = state.copyWith(loadingPages: true);
    final result = await _repository.pageThumbnails(source);
    if (!ref.mounted || state.sources.firstOrNull != source) {
      return;
    }
    state = switch (result) {
      SuccessState(:final data?) => state.copyWith(pageThumbnails: data, loadingPages: false),
      _ => state.copyWith(loadingPages: false, message: trackFailure(result)),
    };
  }

  /// Library picks whose items are deleted there are dropped, so a tool never
  /// runs on a file that no longer exists.
  void _onLibraryItems(DataState<List<LibraryItem>> result) => runFlow('tools.syncLibrary', () {
    if (result case SuccessState(:final data?)) {
      final previous = _libraryIds;
      final current = {for (final item in data) item.id};
      _libraryIds = current;
      if (previous == null || !ref.mounted) {
        return;
      }
      // Only real removals, so a stale emission can't drop a fresh pick.
      bool removed(LocalMediaInfo source) =>
          source.libraryItemId != null &&
          previous.contains(source.libraryItemId) &&
          !current.contains(source.libraryItemId);
      if (state.sources.any(removed)) {
        state = state.copyWith(
          sources: [...state.sources.where((source) => !removed(source))],
          pageThumbnails: const [],
        );
      }
    }
  });
}

final toolSourcesProvider = NotifierProvider.family(ToolSourcesNotifier.new);

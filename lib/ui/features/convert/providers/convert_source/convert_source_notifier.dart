import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/repositories/convert_repository.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';

part 'convert_source_state.dart';

/// The file picked for conversion and what it can become. Keep-alive, so the
/// pick survives tab switches. See docs/features/convert.md#providers.
class ConvertSourceNotifier extends BaseNotifier<ConvertSourceState> {
  late final ConvertRepository _repository;

  /// Ids in the Library's latest emission; `null` until the first one.
  Set<String>? _libraryIds;

  @override
  ConvertSourceState build() {
    _repository = GetIt.I<ConvertRepository>();
    final libraryItems = GetIt.I<LibraryRepository>().watchItems().listen(_onLibraryItems);
    ref.onDispose(libraryItems.cancel);
    return const ConvertSourceState();
  }

  Future<void> pickFromLibrary(String id) =>
      runFlow('convert.pickFromLibrary', () => _load(() => _repository.fromLibrary(id)));

  Future<void> pickFromPhotos() => runFlow('convert.pickFromPhotos', () => _load(_repository.pickFromPhotos));

  Future<void> pickFromFiles() => runFlow('convert.pickFromFiles', () => _load(_repository.pickFromFiles));

  /// A file dropped on the window (macOS).
  Future<void> setDropped(String path) => runFlow('convert.drop', () => _load(() => _repository.importFile(path)));

  /// Forgets the pick and deletes its working copy.
  Future<void> clear() => runFlow('convert.clearSource', () async {
    final source = state.source;
    state = const ConvertSourceState();
    if (source != null) {
      await _repository.discard(source);
    }
  });

  /// A Library pick whose item is deleted there is forgotten, so Convert
  /// never offers a file that no longer exists.
  void _onLibraryItems(DataState<List<LibraryItem>> result) => runFlow('convert.syncLibrary', () {
    if (result case SuccessState(:final data?)) {
      final previous = _libraryIds;
      final current = {for (final item in data) item.id};
      _libraryIds = current;
      final id = state.source?.libraryItemId;
      // Only real removals, so a stale emission can't drop a fresh pick.
      if (ref.mounted && id != null && (previous?.contains(id) ?? false) && !current.contains(id)) {
        state = const ConvertSourceState();
      }
    }
  });

  Future<void> _load(FutureData<LocalMediaInfo?> Function() read) async {
    if (state.isReading) {
      return;
    }
    final previous = state.source;
    final idle = previous == null ? StateStatus.idle : StateStatus.loaded;
    state = state.copyWith(status: .loading);
    final result = await read();
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(:final data?):
        final targets = await _repository.targetsFor(data);
        if (!ref.mounted) {
          return;
        }
        state = ConvertSourceState(
          source: data,
          targets: targets,
          compressFormat: _repository.compressFormatFor(data),
          status: .loaded,
        );
        if (previous != null && previous.path != data.path) {
          await _repository.discard(previous);
        }
      case SuccessState():
        // Cancelled the picker.
        state = state.copyWith(status: idle);
      default:
        state = state.copyWith(status: idle, message: trackFailure(result));
    }
  }
}

final convertSourceProvider = NotifierProvider(ConvertSourceNotifier.new);

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';

part 'media_viewer_state.dart';

/// The viewer's open item and the ids it can swipe through. AutoDispose:
/// lives as long as the viewer.
class MediaViewerNotifier extends BaseNotifier<MediaViewerState> {
  @override
  MediaViewerState build() => const MediaViewerState();

  /// Opens [id] among [ids] (the grid's visible order).
  void open(String id, List<String> ids) {
    final list = ids.contains(id) ? ids : [id, ...ids];
    state = state.copyWith(ids: list, index: list.indexOf(id), status: .loaded);
  }

  void show(int index) {
    if (index >= 0 && index < state.ids.length) {
      state = state.copyWith(index: index);
    }
  }

  void next() => show(state.index + 1);

  void previous() => show(state.index - 1);

  /// Drops ids whose items are gone (deleted), keeping the position.
  void retain(Set<String> existing) {
    final ids = state.ids.where(existing.contains).toList();
    if (ids.length == state.ids.length) {
      return;
    }
    state = state.copyWith(ids: ids, index: state.index.clamp(0, ids.isEmpty ? 0 : ids.length - 1));
  }
}

final mediaViewerProvider = NotifierProvider.autoDispose(MediaViewerNotifier.new);

import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/save_destination.dart';
import 'package:media_downloader/domain/models/save_result.dart';
import 'package:media_downloader/domain/repositories/library_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:media_downloader/ui/features/settings/providers/settings/settings_notifier.dart';

part 'library_actions_state.dart';

/// Save to Photos / Files, Share and Delete for Library items, and the
/// "remove from app?" prompt after a confirmed save. The View confirms
/// deletes and shows the prompt (`pendingRemovePrompt`).
/// See docs/features/library.md#save-and-the-remove-prompt.
class LibraryActionsNotifier extends BaseNotifier<LibraryActionsState> {
  late final LibraryRepository _library;
  SettingsNotifier? _settings;

  @override
  LibraryActionsState build() {
    _library = GetIt.I<LibraryRepository>();
    _settings = ref.read(settingsProvider.notifier);
    return const LibraryActionsState();
  }

  Future<void> saveToPhotos(List<String> ids) => runFlow('library.saveToPhotos', () async {
    if (ids.isEmpty) {
      return;
    }
    _setBusy(ids, busy: true);
    final result = await _library.saveToPhotos(ids);
    if (!ref.mounted) {
      return;
    }
    _setBusy(ids, busy: false);
    _afterSave(result, ids, .photos);
  });

  Future<void> saveToFiles(String id) => runFlow('library.saveToFiles', () async {
    _setBusy([id], busy: true);
    final result = await _library.saveToFiles(id);
    if (!ref.mounted) {
      return;
    }
    _setBusy([id], busy: false);
    _afterSave(result, [id], .files);
  });

  /// Opens the share sheet. Never followed by the remove prompt.
  Future<void> share(List<String> ids) => runFlow('library.share', () async {
    final result = await _library.share(ids);
    if (result case FailureState() when ref.mounted) {
      state = state.copyWith(message: trackFailure(result));
    }
  });

  /// Deletes the files, thumbnails and rows. The View confirms first.
  Future<void> delete(List<String> ids) => runFlow('library.delete', () async {
    final result = await _library.remove(ids);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      message: switch (result) {
        FailureState() => trackFailure(result),
        _ => const SuccessMessage(LibraryMessages.deleted),
      },
    );
  });

  /// "Remove" in the prompt: deletes the saved items.
  Future<void> confirmRemoveAfterSave({bool dontAskAgain = false}) => runFlow('library.removeAfterSave', () async {
    final prompt = state.pendingRemovePrompt;
    state = state.copyWith(clearPrompt: true);
    await _turnOffPrompt(dontAskAgain);
    if (prompt != null) {
      await delete(prompt.ids);
    }
  });

  /// "Keep" in the prompt (or dismissing it).
  Future<void> dismissRemovePrompt({bool dontAskAgain = false}) => runFlow('library.keepAfterSave', () async {
    state = state.copyWith(clearPrompt: true);
    await _turnOffPrompt(dontAskAgain);
  });

  void _afterSave(DataState<SaveResult> result, List<String> ids, SaveDestination destination) {
    switch (result) {
      case SuccessState(data: .saved):
        final askRemove = ref.read(settingsProvider).settings.askRemoveAfterSave;
        state = state.copyWith(
          message: SuccessMessage(
            destination == .photos ? LibraryMessages.savedToPhotos : LibraryMessages.savedToFiles,
          ),
          pendingRemovePrompt: askRemove ? PendingRemovePrompt(ids: ids, destination: destination) : null,
          clearPrompt: !askRemove,
        );
      case SuccessState():
        // Cancelled: nothing to say.
        break;
      case FailureState():
        state = state.copyWith(message: trackFailure(result));
      case LoadingState():
        break;
    }
  }

  Future<void> _turnOffPrompt(bool dontAskAgain) async {
    if (!dontAskAgain) {
      return;
    }
    // SettingsNotifier shows its own failure.
    await _settings?.setAskRemoveAfterSave(false);
  }

  void _setBusy(List<String> ids, {required bool busy}) {
    final busyIds = {...state.busyIds};
    busy ? busyIds.addAll(ids) : busyIds.removeAll(ids);
    state = state.copyWith(busyIds: busyIds);
  }
}

final libraryActionsProvider = NotifierProvider(LibraryActionsNotifier.new);

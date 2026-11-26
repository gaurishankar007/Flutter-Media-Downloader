import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/storage_usage.dart';
import 'package:media_downloader/domain/repositories/library_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';

part 'storage_state.dart';

/// Settings → Library & storage: sizes by kind and "clear saved items".
/// Refreshes whenever the Library changes. The View confirms the clear.
class StorageNotifier extends BaseNotifier<StorageState> {
  late final LibraryRepository _library;

  @override
  StorageState build() {
    _library = GetIt.I<LibraryRepository>();
    final subscription = _library.watchItems().listen((_) => refresh());
    ref.onDispose(subscription.cancel);
    return const StorageState(status: .loading);
  }

  Future<void> refresh() => runFlow('storage.refresh', () async {
    final result = await _library.storageUsage();
    if (!ref.mounted) {
      return;
    }
    state = switch (result) {
      SuccessState(:final data?) => state.copyWith(usage: data, status: .loaded),
      _ => state.copyWith(status: .error),
    };
  });

  Future<void> clearSaved() => runFlow('storage.clearSaved', () async {
    if (state.clearing) {
      return;
    }
    state = state.copyWith(clearing: true);
    final result = await _library.removeSaved();
    if (!ref.mounted) {
      return;
    }
    state = switch (result) {
      SuccessState(:final data) => state.copyWith(
        clearing: false,
        message: SuccessMessage(SettingsMessages.cleared(data ?? 0)),
      ),
      _ => state.copyWith(clearing: false, message: trackFailure(result)),
    };
  });
}

final storageProvider = NotifierProvider.autoDispose(StorageNotifier.new);

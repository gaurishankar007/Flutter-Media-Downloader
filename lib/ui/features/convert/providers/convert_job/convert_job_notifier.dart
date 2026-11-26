import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/convert_request.dart';
import 'package:media_downloader/domain/models/job_progress.dart';
import 'package:media_downloader/domain/models/job_stage.dart';
import 'package:media_downloader/domain/models/library_item.dart';
import 'package:media_downloader/domain/models/save_result.dart';
import 'package:media_downloader/domain/repositories/library_repository.dart';
import 'package:media_downloader/domain/use_cases/convert_media_use_case.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:uuid/uuid.dart';

part 'convert_job_state.dart';

/// The running conversion and its result. Keep-alive, so leaving the screen
/// never cancels it. See docs/features/convert.md#providers.
class ConvertJobNotifier extends BaseNotifier<ConvertJobState> {
  late final ConvertMediaUseCase _convert;
  late final LibraryRepository _library;
  StreamSubscription<JobProgress>? _subscription;

  @override
  ConvertJobState build() {
    _convert = GetIt.I<ConvertMediaUseCase>();
    _library = GetIt.I<LibraryRepository>();
    ref.onDispose(() => _subscription?.cancel());
    return const ConvertJobState();
  }

  void start(ConvertRequest request) => runFlow('convert.start', () {
    if (state.isActive) {
      return;
    }
    final jobId = const Uuid().v4();
    state = ConvertJobState(
      jobId: jobId,
      request: request,
      progress: const JobProgress(stage: .queued),
    );
    _subscription = _convert.run(jobId, request).listen(_onProgress, onDone: () => _subscription = null);
  });

  Future<void> cancel() => runFlow('convert.cancel', () async {
    final jobId = state.jobId;
    if (jobId == null || !state.isActive) {
      return;
    }
    // ffmpeg reports the cancel itself; anything else just stops here.
    if (state.stage == .processing && state.request?.format.kind != .photo) {
      await _convert.cancel(jobId);
      return;
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
    state = state.copyWith(progress: const JobProgress(stage: .cancelled));
  });

  /// Forgets a finished job (Done, Try again).
  void reset() {
    if (!state.isActive) {
      state = const ConvertJobState();
    }
  }

  Future<void> saveToPhotos() => runFlow('convert.saveToPhotos', () async {
    final id = state.result?.id;
    if (id == null) {
      return;
    }
    state = state.copyWith(busy: true);
    final result = await _library.saveToPhotos([id]);
    _afterSave(result, LibraryMessages.savedToPhotos);
  });

  Future<void> saveToFiles() => runFlow('convert.saveToFiles', () async {
    final id = state.result?.id;
    if (id == null) {
      return;
    }
    state = state.copyWith(busy: true);
    final result = await _library.saveToFiles(id);
    _afterSave(result, LibraryMessages.savedToFiles);
  });

  Future<void> share() => runFlow('convert.share', () async {
    final id = state.result?.id;
    if (id == null) {
      return;
    }
    final result = await _library.share([id]);
    if (result case FailureState() when ref.mounted) {
      state = state.copyWith(message: trackFailure(result));
    }
  });

  void _afterSave(DataState<SaveResult> result, String savedText) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      busy: false,
      message: switch (result) {
        SuccessState(data: SaveResult.saved) => SuccessMessage(savedText),
        FailureState() => trackFailure(result),
        _ => null,
      },
    );
  }

  Future<void> _onProgress(JobProgress progress) => runFlow('convert.progress', () async {
    if (!ref.mounted) {
      return;
    }
    if (progress.stage != .done) {
      state = state.copyWith(progress: progress);
      return;
    }
    final item = await _findItem(progress.libraryItemIds.firstOrNull);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      progress: progress,
      result: item,
      resultThumbnailPath: switch (item?.thumbnailRelativePath) {
        final thumbnail? => _library.absolutePath(thumbnail),
        null => null,
      },
    );
  });

  Future<LibraryItem?> _findItem(String? id) async {
    if (id == null) {
      return null;
    }
    final items = await _library.watchItems().first;
    return items.data?.where((item) => item.id == id).firstOrNull;
  }
}

final convertJobProvider = NotifierProvider(ConvertJobNotifier.new);

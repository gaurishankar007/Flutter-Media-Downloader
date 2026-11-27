import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/background_activity.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/download_request.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/repositories/background_work_repository.dart';
import 'package:media_tool/domain/repositories/job_repository.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:media_tool/domain/use_cases/download_media_use_case.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:uuid/uuid.dart';

part 'download_queue_state.dart';

/// Every download job and its live progress. Keep-alive, so leaving the
/// screen never stops a download. Runs at most [_maxParallel] at once.
/// See docs/features/download.md.
class DownloadQueueNotifier extends BaseNotifier<DownloadQueueState> {
  static const _maxParallel = 2;

  late final JobRepository _jobs;
  late final LibraryRepository _library;
  late final DownloadMediaUseCase _download;
  late final BackgroundWorkRepository _background;
  final _running = <String, StreamSubscription<JobProgress>>{};

  /// Ids in the Library's latest emission; `null` until the first one.
  Set<String>? _libraryIds;

  @override
  DownloadQueueState build() {
    _jobs = GetIt.I<JobRepository>();
    _library = GetIt.I<LibraryRepository>();
    _download = GetIt.I<DownloadMediaUseCase>();
    _background = GetIt.I<BackgroundWorkRepository>();
    final cancelRequests = _background.cancelRequests.listen(cancel);
    final libraryItems = _library.watchItems().listen(_onLibraryItems);
    // Keeps the background service and its notification in step with the queue.
    listenSelf((_, next) => _background.update(_activityOf(next)));
    ref.onDispose(() {
      cancelRequests.cancel();
      libraryItems.cancel();
      _background.update(null);
      for (final subscription in _running.values) {
        subscription.cancel();
      }
    });
    Future.microtask(_load);
    return const DownloadQueueState(status: .loading);
  }

  void enqueue(DownloadRequest request) => runFlow('download.enqueue', () {
    final job = DownloadJob(id: const Uuid().v4(), request: request, createdAt: DateTime.now());
    state = state.copyWith(jobs: [job, ...state.jobs], message: const SuccessMessage(DownloadMessages.added));
    // Android 13+: the progress notification needs it; downloads run either way.
    _background.requestNotificationPermission();
    _persist(job);
    _schedule();
  });

  Future<void> cancel(String id) => runFlow('download.cancel', () async {
    final job = _job(id);
    if (job == null) {
      return;
    }
    if (_running.containsKey(id)) {
      // The run's stream reports cancelled.
      await _download.cancel(id);
      return;
    }
    _update(job.copyWith(progress: const JobProgress(stage: .cancelled)));
  });

  void retry(String id) => runFlow('download.retry', () {
    final job = _job(id);
    if (job == null || !job.stage.isFinished) {
      return;
    }
    _update(job.copyWith(progress: const JobProgress(stage: .queued)));
    _schedule();
  });

  /// Removes the card only; files stay.
  Future<void> dismiss(String id) => runFlow('download.dismiss', () => _forget([id]));

  /// Removes every finished card; files stay.
  Future<void> clearFinished() =>
      runFlow('download.clearFinished', () => _forget([for (final job in state.finished) job.id]));

  Future<void> share(String id) => runFlow('download.share', () async {
    final ids = _job(id)?.progress.libraryItemIds ?? const [];
    final result = await _library.share(ids);
    if (result case FailureState() when ref.mounted) {
      state = state.copyWith(message: trackFailure(result));
    }
  });

  /// Deletes the job's files from the app and removes the card. The View
  /// confirms first.
  Future<void> remove(String id) => runFlow('download.remove', () async {
    final ids = _job(id)?.progress.libraryItemIds ?? const [];
    final result = await _library.remove(ids);
    if (!ref.mounted) {
      return;
    }
    if (result case FailureState()) {
      state = state.copyWith(message: trackFailure(result));
      return;
    }
    await _forget([id]);
  });

  Future<void> _load() => runFlow('download.load', () async {
    final result = await _jobs.getAll();
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(:final data?):
        // Jobs added while loading stay on top.
        state = state.copyWith(jobs: [...state.jobs, ...data], status: .loaded);
        data.where((job) => job.stage == .failed).forEach(_persist);
        // Files deleted from the Library while the app was closed.
        if (_libraryIds case final ids?) {
          await _dropDeleted((id) => !ids.contains(id));
        }
      default:
        state = state.copyWith(status: .error, message: trackFailure(result));
    }
  });

  /// Keeps finished cards in step with the Library: deleting a download's
  /// files there removes its card here (or trims a photo post's card).
  void _onLibraryItems(DataState<List<LibraryItem>> result) => runFlow('download.syncLibrary', () async {
    if (result case SuccessState(:final data?)) {
      final previous = _libraryIds;
      final current = {for (final item in data) item.id};
      _libraryIds = current;
      if (!ref.mounted || state.status != .loaded) {
        return;
      }
      // After the first emission only react to real removals, so a stale
      // emission can't drop a job that has just finished saving.
      await _dropDeleted(
        previous == null ? (id) => !current.contains(id) : (id) => previous.contains(id) && !current.contains(id),
      );
    }
  });

  Future<void> _dropDeleted(bool Function(String id) isDeleted) async {
    final gone = <String>[];
    for (final job in state.jobs) {
      final ids = job.progress.libraryItemIds;
      if (job.stage != .done || !ids.any(isDeleted)) {
        continue;
      }
      final remaining = [
        for (final id in ids)
          if (!isDeleted(id)) id,
      ];
      if (remaining.isEmpty) {
        gone.add(job.id);
      } else {
        _update(
          job.copyWith(
            progress: JobProgress(stage: .done, libraryItemIds: remaining, sizeBytes: job.progress.sizeBytes),
          ),
        );
      }
    }
    if (gone.isNotEmpty) {
      await _forget(gone);
    }
  }

  void _schedule() {
    final queued = state.jobs.reversed.where((job) => job.stage == .queued && !_running.containsKey(job.id));
    queued.take(_maxParallel - _running.length).forEach(_start);
  }

  void _start(DownloadJob job) {
    _running[job.id] = _download
        .run(job)
        .listen(
          (progress) {
            final current = _job(job.id);
            if (current == null) {
              return;
            }
            final stageChanged = current.stage != progress.stage;
            _update(
              current.copyWith(progress: progress),
              persist: stageChanged,
              // Says where the files went: the Library.
              message: stageChanged && progress.stage == .done
                  ? const SuccessMessage(DownloadMessages.addedToLibrary)
                  : null,
            );
          },
          onDone: () {
            _running.remove(job.id);
            _schedule();
          },
        );
  }

  /// The notification's content: the oldest running job, else the next queued one.
  static BackgroundActivity? _activityOf(DownloadQueueState state) {
    final active = state.inProgress.reversed.toList();
    if (active.isEmpty) {
      return null;
    }
    final job = active.firstWhere((job) => job.stage != .queued, orElse: () => active.first);
    final fraction = job.stage == .downloading ? job.progress.fraction : null;
    return BackgroundActivity(
      jobId: job.id,
      title: job.request.title,
      percent: fraction == null ? null : (fraction * 100).round(),
      activeCount: active.length,
    );
  }

  DownloadJob? _job(String id) => state.jobs.where((job) => job.id == id).firstOrNull;

  void _update(DownloadJob job, {bool persist = true, StateMessage? message}) {
    state = state.copyWith(
      jobs: [
        for (final existing in state.jobs)
          if (existing.id == job.id) job else existing,
      ],
      message: message,
    );
    if (persist) {
      _persist(job);
    }
  }

  void _persist(DownloadJob job) => _jobs.save(job);

  Future<void> _forget(List<String> ids) async {
    state = state.copyWith(
      jobs: [
        for (final job in state.jobs)
          if (!ids.contains(job.id)) job,
      ],
    );
    await _jobs.delete(ids);
  }
}

final downloadQueueProvider = NotifierProvider(DownloadQueueNotifier.new);

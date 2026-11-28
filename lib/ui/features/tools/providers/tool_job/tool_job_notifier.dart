import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/job_stage.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:media_tool/domain/use_cases/run_tool_use_case.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:uuid/uuid.dart';

part 'tool_job_state.dart';

/// One [tool]'s running job and its results. Keep-alive per tool, so leaving
/// the screen never cancels it. See docs/features/tools.md#providers.
class ToolJobNotifier(final Tool tool) extends BaseNotifier<ToolJobState> {
  late final RunToolUseCase _runTool;
  late final LibraryRepository _library;
  StreamSubscription<JobProgress>? _subscription;

  /// Ids in the Library's latest emission; `null` until the first one.
  Set<String>? _libraryIds;

  @override
  ToolJobState build() {
    _runTool = GetIt.I<RunToolUseCase>();
    _library = GetIt.I<LibraryRepository>();
    final libraryItems = _library.watchItems().listen(_onLibraryItems);
    ref.onDispose(() {
      _subscription?.cancel();
      libraryItems.cancel();
    });
    return const ToolJobState();
  }

  void start(ToolRequest request) => runFlow('tools.start', () {
    if (state.isActive) {
      return;
    }
    final jobId = const Uuid().v4();
    state = ToolJobState(
      jobId: jobId,
      request: request,
      progress: const JobProgress(stage: .queued),
    );
    _subscription = _runTool.run(jobId, request).listen(_onProgress, onDone: () => _subscription = null);
  });

  Future<void> cancel() => runFlow('tools.cancel', () async {
    final jobId = state.jobId;
    if (jobId == null || !state.isActive || state.stage == .saving) {
      return;
    }
    // The runner stops at its next step and reports the cancel itself.
    await _runTool.cancel(jobId);
  });

  /// Forgets a finished job (Done, Start over, Try again).
  void reset() {
    if (!state.isActive) {
      state = const ToolJobState();
    }
  }

  Future<void> share() => runFlow('tools.share', () async {
    final ids = [for (final item in state.results) item.id];
    if (ids.isEmpty) {
      return;
    }
    final result = await _library.share(ids);
    if (result case FailureState() when ref.mounted) {
      state = state.copyWith(message: trackFailure(result));
    }
  });

  Future<void> _onProgress(JobProgress progress) => runFlow('tools.progress', () async {
    if (!ref.mounted) {
      return;
    }
    if (progress.stage != .done) {
      state = state.copyWith(progress: progress);
      return;
    }
    final ids = progress.libraryItemIds;
    final items = (await _library.watchItems().first).data ?? const <LibraryItem>[];
    if (!ref.mounted) {
      return;
    }
    final byId = {for (final item in items) item.id: item};
    final results = [for (final id in ids) ?byId[id]];
    state = state.copyWith(
      progress: progress,
      results: results,
      thumbnails: [
        for (final item in results)
          switch (item.thumbnailRelativePath) {
            final thumbnail? => _library.absolutePath(thumbnail),
            null => null,
          },
      ],
      message: const SuccessMessage(ToolsMessages.addedToLibrary),
    );
  });

  /// Results deleted in the Library leave the result; when none are left the
  /// finished job is forgotten, so Open / Share never point at missing files.
  void _onLibraryItems(DataState<List<LibraryItem>> result) => runFlow('tools.syncLibrary', () {
    if (result case SuccessState(:final data?)) {
      final previous = _libraryIds;
      final current = {for (final item in data) item.id};
      _libraryIds = current;
      if (previous == null || !ref.mounted || state.results.isEmpty) {
        return;
      }
      bool removed(LibraryItem item) => previous.contains(item.id) && !current.contains(item.id);
      if (!state.results.any(removed)) {
        return;
      }
      final kept = [
        for (final (index, item) in state.results.indexed)
          if (!removed(item)) (item, state.thumbnails[index]),
      ];
      if (kept.isEmpty) {
        reset();
        return;
      }
      state = state.copyWith(
        results: [for (final (item, _) in kept) item],
        thumbnails: [for (final (_, path) in kept) path],
      );
    }
  });
}

final toolJobProvider = NotifierProvider.family(ToolJobNotifier.new);

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/tool_event.dart';
import 'package:media_tool/domain/models/tool_output.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/domain/repositories/tool_repository.dart';

/// Runs one tool end to end: PDFium / ffmpeg → into the Library. The last
/// [JobProgress] is done, failed or cancelled. See docs/features/tools.md.
@injectable
final class RunToolUseCase({required final ToolRepository _tools}) {
  Stream<JobProgress> run(String jobId, ToolRequest request) async* {
    try {
      List<ToolOutput>? outputs;
      await for (final event in _tools.run(jobId, request)) {
        switch (event) {
          case ToolProgressed(:final progress):
            yield progress;
          case ToolFinished(outputs: final files):
            outputs = files;
          case ToolFailed(:final message):
            yield JobProgress(stage: .failed, errorMessage: message);
            return;
          case ToolCancelled():
            yield const JobProgress(stage: .cancelled);
            return;
        }
      }
      if (outputs == null) {
        return;
      }
      yield const JobProgress(stage: .saving);
      final saved = await _tools.save(request, outputs);
      yield switch (saved) {
        SuccessState(:final data?) => JobProgress(
          stage: .done,
          libraryItemIds: [for (final item in data) item.id],
          sizeBytes: data.fold<int>(0, (total, item) => total + item.sizeBytes),
        ),
        _ => JobProgress(stage: .failed, errorMessage: saved.message),
      };
    } finally {
      await _tools.clearWork(jobId);
    }
  }

  Future<void> cancel(String jobId) => _tools.cancel(jobId);
}

import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/domain/models/convert_request.dart';
import 'package:media_downloader/domain/models/download_event.dart';
import 'package:media_downloader/domain/models/job_progress.dart';
import 'package:media_downloader/domain/repositories/convert_repository.dart';

/// Runs one conversion end to end: ffmpeg / image encoder → into the Library.
/// The last [JobProgress] is done, failed or cancelled. See docs/features/convert.md.
@injectable
final class ConvertMediaUseCase({required final ConvertRepository _convert}) {
  Stream<JobProgress> run(String jobId, ConvertRequest request) async* {
    try {
      String? outputPath;
      String? thumbnailPath;
      await for (final event in _convert.run(jobId, request)) {
        switch (event) {
          case DownloadProgressed(:final progress):
            yield progress;
          case DownloadFinished(mediaPath: final media, thumbnailPath: final thumbnail):
            outputPath = media;
            thumbnailPath = thumbnail;
          case DownloadFailed(:final message):
            yield JobProgress(stage: .failed, errorMessage: message);
            return;
          case DownloadCancelled():
            yield const JobProgress(stage: .cancelled);
            return;
          case PostDownloadFinished():
            break;
        }
      }
      if (outputPath == null) {
        return;
      }
      yield const JobProgress(stage: .saving);
      final saved = await _convert.save(request, outputPath: outputPath, thumbnailPath: thumbnailPath);
      yield switch (saved) {
        SuccessState(:final data?) => JobProgress(stage: .done, libraryItemIds: [data.id], sizeBytes: data.sizeBytes),
        _ => JobProgress(stage: .failed, errorMessage: saved.message),
      };
    } finally {
      await _convert.clearWork(jobId);
    }
  }

  Future<void> cancel(String jobId) => _convert.cancel(jobId);
}

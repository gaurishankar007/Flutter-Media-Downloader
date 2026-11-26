import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/download_job.dart';

/// Stored Download-screen jobs.
abstract interface class JobRepository {
  /// All jobs, newest first. Jobs a killed app left running come back failed.
  FutureList<DownloadJob> getAll();

  FutureVoid save(DownloadJob job);

  FutureVoid delete(List<String> ids);
}

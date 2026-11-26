import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/local/job_local_service.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/repositories/job_repository.dart';

@LazySingleton(as: JobRepository)
final class JobRepositoryImpl({required final JobLocalService _localService}) implements JobRepository {
  @override
  FutureList<DownloadJob> getAll() async {
    final result = await _localService.getAll();
    if (result case SuccessState(:final data?)) {
      // A job still "running" in storage was cut off by the app being killed.
      final jobs = [
        for (final job in data)
          if (job.stage == .queued || job.stage.isActive)
            job.copyWith(
              progress: const JobProgress(stage: .failed, errorMessage: DownloadMessages.interrupted),
            )
          else
            job,
      ];
      return SuccessState(data: jobs);
    }
    return result;
  }

  @override
  FutureVoid save(DownloadJob job) => _localService.save(job);

  @override
  FutureVoid delete(List<String> ids) => _localService.deleteByIds(ids);
}

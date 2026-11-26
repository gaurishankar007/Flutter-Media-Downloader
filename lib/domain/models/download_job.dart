import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/download_request.dart';
import 'package:media_downloader/domain/models/job_progress.dart';
import 'package:media_downloader/domain/models/job_stage.dart';

/// A download on the Download screen. Stage changes are stored; live numbers
/// (percent, speed) only live in [progress].
final class const DownloadJob({
  required final String id,
  required final DownloadRequest request,
  required final DateTime createdAt,
  final JobProgress progress = const JobProgress(stage: .queued),
}) extends Equatable {
  JobStage get stage => progress.stage;

  DownloadJob copyWith({JobProgress? progress}) =>
      DownloadJob(id: id, request: request, createdAt: createdAt, progress: progress ?? this.progress);

  @override
  List<Object?> get props => [id, request, createdAt, progress];
}

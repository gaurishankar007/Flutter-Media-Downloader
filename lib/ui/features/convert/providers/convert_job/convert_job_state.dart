part of 'convert_job_notifier.dart';

final class const ConvertJobState({
  final String? jobId,
  final ConvertRequest? request,
  final JobProgress? progress,

  /// The Library item the job made, once done.
  final LibraryItem? result,
  final String? resultThumbnailPath,

  /// A save or share is running.
  final bool busy = false,
  super.status,
  super.message,
}) extends BaseState {
  JobStage? get stage => progress?.stage;

  bool get isActive => stage != null && !stage!.isFinished;

  bool get isDone => stage == .done;

  bool get canSaveToPhotos => result != null && (result!.kind == .video || result!.kind == .photo);

  ConvertJobState copyWith({
    JobProgress? progress,
    LibraryItem? result,
    String? resultThumbnailPath,
    bool? busy,
    StateMessage? message,
  }) => ConvertJobState(
    jobId: jobId,
    request: request,
    progress: progress ?? this.progress,
    result: result ?? this.result,
    resultThumbnailPath: resultThumbnailPath ?? this.resultThumbnailPath,
    busy: busy ?? this.busy,
    status: status,
    message: message,
  );

  @override
  List<Object?> get props => [jobId, request, progress, result, resultThumbnailPath, busy, ...super.props];
}

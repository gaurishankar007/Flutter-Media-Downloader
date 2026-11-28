part of 'tool_job_notifier.dart';

final class const ToolJobState({
  final String? jobId,
  final ToolRequest? request,
  final JobProgress? progress,

  /// The Library items the job made, once done, in order.
  final List<LibraryItem> results = const [],

  /// Each result's thumbnail (absolute), or null.
  final List<String?> thumbnails = const [],
  super.status,
  super.message,
}) extends BaseState {
  JobStage? get stage => progress?.stage;

  bool get isActive => stage != null && !stage!.isFinished;

  bool get isDone => stage == .done;

  bool get hasJob => request != null;

  /// The results' post id when they're grouped.
  String? get groupId => results.length > 1 ? results.first.groupId : null;

  int get resultBytes => results.fold(0, (total, item) => total + item.sizeBytes);

  ToolJobState copyWith({
    JobProgress? progress,
    List<LibraryItem>? results,
    List<String?>? thumbnails,
    StateMessage? message,
  }) => ToolJobState(
    jobId: jobId,
    request: request,
    progress: progress ?? this.progress,
    results: results ?? this.results,
    thumbnails: thumbnails ?? this.thumbnails,
    status: status,
    message: message,
  );

  @override
  List<Object?> get props => [jobId, request, progress, results, thumbnails, ...super.props];
}

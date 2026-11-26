part of 'download_queue_notifier.dart';

final class const DownloadQueueState({final List<DownloadJob> jobs = const [], super.status, super.message})
    extends BaseState {
  /// Queued and running, newest first.
  List<DownloadJob> get inProgress => [
    for (final job in jobs)
      if (!job.stage.isFinished) job,
  ];

  /// Done, failed and cancelled, newest first.
  List<DownloadJob> get finished => [
    for (final job in jobs)
      if (job.stage.isFinished) job,
  ];

  DownloadQueueState copyWith({List<DownloadJob>? jobs, StateStatus? status, StateMessage? message}) =>
      DownloadQueueState(jobs: jobs ?? this.jobs, status: status ?? this.status, message: message);

  @override
  List<Object?> get props => [jobs, ...super.props];
}

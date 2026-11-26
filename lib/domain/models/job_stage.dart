/// Where a download or conversion job is. See docs/features/download.md.
enum JobStage {
  queued,
  downloading,
  processing,
  saving,
  done,
  failed,
  cancelled;

  bool get isActive => this == .downloading || this == .processing || this == .saving;

  bool get isFinished => this == .done || this == .failed || this == .cancelled;
}

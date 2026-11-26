import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/job_stage.dart';

/// What a running job is doing during [JobStage.processing].
enum ProcessingStep { merging, extractingAudio, convertingForIphone, convertingPhotos, makingSlideshow, finishing }

/// One progress update of a job. See docs/engine/media_engine.md#progress.
final class const JobProgress({
  required final JobStage stage,

  /// 0–1, or `null` when unknown (indeterminate bar).
  final double? fraction,
  final double? speedBytesPerSecond,
  final int? etaSeconds,
  final ProcessingStep? step,

  /// Set with [JobStage.done]: the Library items created.
  final List<String> libraryItemIds = const [],
  final int? sizeBytes,

  /// Set with [JobStage.failed]: the message to show.
  final String? errorMessage,
}) extends Equatable {
  @override
  List<Object?> get props => [
    stage,
    fraction,
    speedBytesPerSecond,
    etaSeconds,
    step,
    libraryItemIds,
    sizeBytes,
    errorMessage,
  ];
}

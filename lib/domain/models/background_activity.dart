import 'package:equatable/equatable.dart';

/// What the background download notification shows: the first active job and
/// how many are running or waiting.
final class const BackgroundActivity({
  required final String jobId,
  required final String title,
  required final int activeCount,
  final int? percent,
}) extends Equatable {
  @override
  List<Object?> get props => [jobId, title, activeCount, percent];
}

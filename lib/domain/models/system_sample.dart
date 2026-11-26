import 'package:equatable/equatable.dart';

/// One reading of the System monitor. A field is null when its metric isn't
/// supported, or (for rates) until a second reading exists to compare with.
final class const SystemSample({
  final int? memoryUsedBytes,
  final int? memoryTotalBytes,
  final double? cpuPercent,
  final double? gpuPercent,
  final double? downloadBytesPerSecond,
  final double? uploadBytesPerSecond,
}) extends Equatable {
  /// RAM in use, 0–1.
  double? get memoryFraction => switch ((memoryUsedBytes, memoryTotalBytes)) {
    (final used?, final total?) when total > 0 => (used / total).clamp(0, 1),
    _ => null,
  };

  @override
  List<Object?> get props => [
    memoryUsedBytes,
    memoryTotalBytes,
    cpuPercent,
    gpuPercent,
    downloadBytesPerSecond,
    uploadBytesPerSecond,
  ];
}

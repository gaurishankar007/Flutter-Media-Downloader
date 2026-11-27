import 'package:equatable/equatable.dart';

/// Measured throughput in bytes per second. [copyBytesPerSecond] is RAM only.
final class const SpeedTestResult({
  required final double readBytesPerSecond,
  required final double writeBytesPerSecond,
  final double? copyBytesPerSecond,
}) extends Equatable {
  @override
  List<Object?> get props => [readBytesPerSecond, writeBytesPerSecond, copyBytesPerSecond];
}

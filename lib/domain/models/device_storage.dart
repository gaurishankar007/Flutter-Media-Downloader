import 'package:equatable/equatable.dart';

/// Space on the volume that holds the app's files, and how much of it the
/// app's own folder takes ([appBytes] null until it has been measured).
final class const DeviceStorage({
  required final int totalBytes,
  required final int freeBytes,
  final int? appBytes,
}) extends Equatable {
  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);

  /// Used space, 0–1.
  double get usedFraction => totalBytes > 0 ? usedBytes / totalBytes : 0;

  /// The app's files as a share of the whole volume, 0–1.
  double? get appFraction => switch (appBytes) {
    final bytes? when totalBytes > 0 => (bytes / totalBytes).clamp(0, 1),
    _ => null,
  };

  DeviceStorage withAppBytes(int? appBytes) =>
      DeviceStorage(totalBytes: totalBytes, freeBytes: freeBytes, appBytes: appBytes);

  @override
  List<Object?> get props => [totalBytes, freeBytes, appBytes];
}

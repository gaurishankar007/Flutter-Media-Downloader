import 'package:equatable/equatable.dart';

/// How much space the Library takes, by kind, and how much of it is already
/// saved to Photos or Files.
final class const StorageUsage({
  final int videoBytes = 0,
  final int audioBytes = 0,
  final int photoBytes = 0,
  final int savedCount = 0,
  final int savedBytes = 0,
}) extends Equatable {
  int get totalBytes => videoBytes + audioBytes + photoBytes;

  @override
  List<Object?> get props => [videoBytes, audioBytes, photoBytes, savedCount, savedBytes];
}

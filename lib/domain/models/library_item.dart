import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/site.dart';

/// One file in the Library. Paths are relative to the app's base folder.
final class const LibraryItem({
  required final String id,
  required final MediaKind kind,
  required final String title,
  required final String relativePath,
  required final int sizeBytes,
  required final String format,
  required final DateTime createdAt,
  final Site? site,
  final String? uploader,
  final String? sourceUrl,
  final String? thumbnailRelativePath,
  final int? durationMs,
  final DateTime? savedToPhotosAt,
  final DateTime? savedToFilesAt,

  /// Shared by every item of one post (carousel), so the Library groups them.
  final String? groupId,

  /// Position inside the group, from 0.
  final int? groupIndex,
}) extends Equatable {
  /// Saved to Photos or Files at least once (the ✓ on the card).
  bool get isSaved => savedToPhotosAt != null || savedToFilesAt != null;

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    relativePath,
    sizeBytes,
    format,
    createdAt,
    site,
    uploader,
    sourceUrl,
    thumbnailRelativePath,
    durationMs,
    savedToPhotosAt,
    savedToFilesAt,
    groupId,
    groupIndex,
  ];
}

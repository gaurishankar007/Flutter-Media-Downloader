import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/library_item.dart';

/// A [LibraryItem] with its file and thumbnail resolved to absolute paths for
/// players and images. In the grid, one entry can stand for a whole post
/// ([groupIds]: every item of the carousel, in order).
final class const LibraryEntry({
  required final LibraryItem item,
  required final String filePath,
  final String? thumbnailPath,
  final bool canSaveToPhotos = true,
  final List<String> groupIds = const [],
}) extends Equatable {
  String get id => item.id;

  /// More than one item behind this card.
  bool get isGroup => groupIds.length > 1;

  /// The ids this card acts on: the group, or just this item.
  List<String> get ids => isGroup ? groupIds : [item.id];

  LibraryEntry withGroup(List<String> ids) => LibraryEntry(
    item: item,
    filePath: filePath,
    thumbnailPath: thumbnailPath,
    canSaveToPhotos: canSaveToPhotos,
    groupIds: ids,
  );

  @override
  List<Object?> get props => [item, filePath, thumbnailPath, canSaveToPhotos, groupIds];
}

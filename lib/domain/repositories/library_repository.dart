import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/download_request.dart';
import 'package:media_downloader/domain/models/library_item.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/domain/models/post_file.dart';
import 'package:media_downloader/domain/models/save_result.dart';
import 'package:media_downloader/domain/models/storage_usage.dart';

/// The Library: files in the app's downloads folder and their rows.
abstract interface class LibraryRepository {
  /// Moves a finished download into `downloads/` under a readable name and
  /// adds its row.
  FutureData<LibraryItem> addDownload(DownloadRequest request, {required String mediaPath, String? thumbnailPath});

  /// Moves a photo post's files into `downloads/` as `<user> <postid> 01.jpg`,
  /// `02.jpg`… and adds one row each, sharing a `groupId` when there are
  /// several. Photos get a small thumbnail. See docs/extractors/photo_extractors.md.
  FutureList<LibraryItem> addPost(DownloadRequest request, {required List<PostFile> files});

  /// Deletes the items' files, thumbnails and rows.
  FutureVoid remove(List<String> ids);

  /// Space used by kind, and by items already saved to Photos or Files.
  FutureData<StorageUsage> storageUsage();

  /// Deletes every item already saved to Photos or Files. Returns how many.
  FutureData<int> removeSaved();

  /// Opens the system share sheet with the items' files.
  FutureVoid share(List<String> ids);

  /// Every item, newest first, updated on each change.
  StreamData<List<LibraryItem>> watchItems();

  /// The absolute path of a stored relative path (file or thumbnail).
  String absolutePath(String relativePath);

  /// Whether [kind] can be saved to Photos / the gallery (audio can't).
  bool canSaveToPhotos(MediaKind kind);

  /// Copies the items into Photos / the gallery and marks them saved.
  FutureData<SaveResult> saveToPhotos(List<String> ids);

  /// Asks where to save the item's file, copies it there and marks it saved.
  FutureData<SaveResult> saveToFiles(String id);
}

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/core/utils/filename_utils.dart';
import 'package:media_tool/core/utils/mime_utils.dart';
import 'package:media_tool/data/services/local/library_local_service.dart';
import 'package:media_tool/data/services/platform/file_export/file_export_service.dart';
import 'package:media_tool/data/services/platform/gallery_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/platform/share_service.dart';
import 'package:media_tool/domain/models/download_request.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/post_file.dart';
import 'package:media_tool/domain/models/save_result.dart';
import 'package:media_tool/domain/models/storage_usage.dart';
import 'package:media_tool/domain/repositories/library_repository.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

@LazySingleton(as: LibraryRepository)
final class LibraryRepositoryImpl({
  required final LibraryLocalService _localService,
  required final AppDirectories _directories,
  required final FileService _files,
  required final ShareService _share,
  required final GalleryService _gallery,
  required final FileExportService _fileExport,
  required final ImageService _images,
  required final ErrorHandler _errorHandler,
}) implements LibraryRepository {
  @override
  FutureData<LibraryItem> addDownload(DownloadRequest request, {required String mediaPath, String? thumbnailPath}) =>
      _errorHandler.execute(action: 'library.addDownload', () async {
        final id = const Uuid().v4();
        final extension = p.extension(mediaPath).replaceFirst('.', '').toLowerCase();
        final suffix = request.kind == .video && request.resolution != null ? '[${request.resolution}p]' : null;
        final name = FilenameUtils.fromTitle(request.title, extension: extension, suffix: suffix);
        final target = p.join(_directories.downloads, _files.uniqueName(_directories.downloads, name));
        await _files.move(mediaPath, target);

        String? thumbnailTarget;
        if (thumbnailPath != null) {
          thumbnailTarget = p.join(_directories.thumbnails, '$id.jpg');
          await _files.move(thumbnailPath, thumbnailTarget);
        }

        final item = LibraryItem(
          id: id,
          kind: request.kind,
          site: request.site,
          title: request.title,
          uploader: request.uploader,
          sourceUrl: request.url,
          relativePath: _directories.relative(target),
          thumbnailRelativePath: thumbnailTarget == null ? null : _directories.relative(thumbnailTarget),
          sizeBytes: await _files.sizeOf(target),
          durationMs: request.durationSeconds == null ? null : request.durationSeconds! * 1000,
          format: extension,
          createdAt: DateTime.now(),
        );
        final inserted = await _localService.insert(item);
        if (inserted case final FailureState<void> failure) {
          // Don't leave a file the Library doesn't know about.
          await _files.delete(target);
          return failure.retype();
        }
        return SuccessState(data: item);
      });

  @override
  FutureList<LibraryItem> addPost(DownloadRequest request, {required List<PostFile> files}) =>
      _errorHandler.execute(action: 'library.addPost', () async {
        final groupId = files.length > 1 ? const Uuid().v4() : null;
        final createdAt = DateTime.now();
        final items = <LibraryItem>[];
        final moved = <String>[];
        for (final (index, file) in files.indexed) {
          final id = const Uuid().v4();
          final extension = p.extension(file.path).replaceFirst('.', '').toLowerCase();
          final name = FilenameUtils.forPostItem(
            uploader: request.uploader,
            postId: request.postId,
            fallback: request.title,
            index: files.length > 1 ? index + 1 : null,
            extension: extension,
          );
          final target = p.join(_directories.downloads, _files.uniqueName(_directories.downloads, name));
          await _files.move(file.path, target);
          moved.add(target);

          final thumbnailTarget = p.join(_directories.thumbnails, '$id.jpg');
          String? thumbnail;
          if (file.kind == .photo) {
            thumbnail = await _errorHandler.executeSafeReturn(() async {
              await _images.thumbnail(target, thumbnailTarget);
              return thumbnailTarget;
            }, onError: (_) => null);
          } else if (file.thumbnailPath case final still?) {
            thumbnail = await _errorHandler.executeSafeReturn(() async {
              await _files.move(still, thumbnailTarget);
              return thumbnailTarget;
            }, onError: (_) => null);
          }

          items.add(
            LibraryItem(
              id: id,
              kind: file.kind,
              site: request.site,
              title: request.title,
              uploader: request.uploader,
              sourceUrl: request.url,
              relativePath: _directories.relative(target),
              thumbnailRelativePath: thumbnail == null ? null : _directories.relative(thumbnail),
              sizeBytes: await _files.sizeOf(target),
              format: extension,
              // Keeps the post's order when sorted newest first.
              createdAt: createdAt.subtract(Duration(milliseconds: index)),
              groupId: groupId,
              groupIndex: groupId == null ? null : index,
            ),
          );
        }
        for (final item in items) {
          final inserted = await _localService.insert(item);
          if (inserted case final FailureState<void> failure) {
            // Don't leave files the Library doesn't know about.
            await _localService.deleteByIds([for (final item in items) item.id]);
            for (final path in moved) {
              await _files.delete(path);
            }
            return failure.retype();
          }
        }
        return SuccessState(data: items);
      });

  @override
  FutureVoid remove(List<String> ids) => _errorHandler.execute(action: 'library.remove', () async {
    final items = await _localService.getByIds(ids);
    if (items case final FailureState<List<LibraryItem>> failure) {
      return failure.retype();
    }
    for (final item in items.data ?? const <LibraryItem>[]) {
      await _files.delete(_directories.resolve(item.relativePath));
      if (item.thumbnailRelativePath case final thumbnail?) {
        await _files.delete(_directories.resolve(thumbnail));
      }
    }
    return await _localService.deleteByIds(ids);
  });

  @override
  FutureData<StorageUsage> storageUsage() => _errorHandler.execute(action: 'library.storageUsage', () async {
    final items = await _localService.watchAll().first;
    int sum(Iterable<LibraryItem> items) => items.fold(0, (total, item) => total + item.sizeBytes);
    final saved = items.where((item) => item.isSaved);
    return SuccessState(
      data: StorageUsage(
        videoBytes: sum(items.where((item) => item.kind == .video)),
        audioBytes: sum(items.where((item) => item.kind == .audio)),
        photoBytes: sum(items.where((item) => item.kind == .photo)),
        documentBytes: sum(items.where((item) => item.kind == .document)),
        savedCount: saved.length,
        savedBytes: sum(saved),
      ),
    );
  });

  @override
  FutureData<int> removeSaved() => _errorHandler.execute(action: 'library.removeSaved', () async {
    final items = await _localService.watchAll().first;
    final ids = [
      for (final item in items)
        if (item.isSaved) item.id,
    ];
    if (ids.isEmpty) {
      return const SuccessState(data: 0);
    }
    final removed = await remove(ids);
    return removed.mapData((_) => ids.length);
  });

  @override
  FutureVoid share(List<String> ids) => _errorHandler.execute(action: 'library.share', () async {
    final items = await _localService.getByIds(ids);
    if (items case final FailureState<List<LibraryItem>> failure) {
      return failure.retype();
    }
    final paths = [for (final item in items.data ?? const <LibraryItem>[]) _directories.resolve(item.relativePath)];
    await _share.shareFiles(paths);
    return const SuccessState.nil();
  });

  @override
  StreamData<List<LibraryItem>> watchItems() =>
      _errorHandler.executeStream(_localService.watchAll(), action: 'library.watch');

  @override
  String absolutePath(String relativePath) => _directories.resolve(relativePath);

  @override
  bool canSaveToPhotos(MediaKind kind) => _gallery.supports(kind);

  @override
  FutureData<SaveResult> saveToPhotos(List<String> ids) =>
      _errorHandler.execute(action: 'library.saveToPhotos', () async {
        final items = await _localService.getByIds(ids);
        if (items case final FailureState<List<LibraryItem>> failure) {
          return failure.retype();
        }
        for (final item in items.data ?? const <LibraryItem>[]) {
          if (!_gallery.supports(item.kind)) {
            continue;
          }
          await _gallery.save(_directories.resolve(item.relativePath), item.kind);
          final marked = await _localService.markSaved(item.id, .photos);
          if (marked case final FailureState<void> failure) {
            return failure.retype();
          }
        }
        return const SuccessState(data: SaveResult.saved);
      });

  @override
  FutureData<SaveResult> saveToFiles(String id) => _errorHandler.execute(action: 'library.saveToFiles', () async {
    final items = await _localService.getByIds([id]);
    if (items case final FailureState<List<LibraryItem>> failure) {
      return failure.retype();
    }
    final item = items.data?.firstOrNull;
    if (item == null) {
      return const SuccessState(data: SaveResult.cancelled);
    }
    final path = _directories.resolve(item.relativePath);
    final saved = await _fileExport.export(path, name: p.basename(path), mimeType: MimeUtils.forPath(path));
    if (!saved) {
      return const SuccessState(data: SaveResult.cancelled);
    }
    final marked = await _localService.markSaved(item.id, .files);
    if (marked case final FailureState<void> failure) {
      return failure.retype();
    }
    return const SuccessState(data: SaveResult.saved);
  });
}

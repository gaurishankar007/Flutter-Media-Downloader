import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/save_destination.dart';
import 'package:media_tool/domain/models/site.dart';

abstract interface class LibraryLocalService {
  /// [origin]: `download` or `convert`.
  FutureVoid insert(LibraryItem item, {String origin = 'download'});

  FutureList<LibraryItem> getByIds(List<String> ids);

  FutureVoid deleteByIds(List<String> ids);

  /// Every item, newest first, re-emitted on each change.
  Stream<List<LibraryItem>> watchAll();

  /// Stamps the item as saved to Photos or Files now.
  FutureVoid markSaved(String id, SaveDestination destination);
}

@LazySingleton(as: LibraryLocalService)
final class LibraryLocalServiceImpl({required final AppDatabase _database, required final ErrorHandler _errorHandler})
    implements LibraryLocalService {
  @override
  FutureVoid insert(LibraryItem item, {String origin = 'download'}) =>
      _errorHandler.execute(action: 'library.insert', () async {
        final row = LibraryItemLocalCompanion.insert(
          id: item.id,
          kind: item.kind.name,
          site: Value(item.site?.name),
          title: item.title,
          uploader: Value(item.uploader),
          sourceUrl: Value(item.sourceUrl),
          relativePath: item.relativePath,
          thumbnailRelativePath: Value(item.thumbnailRelativePath),
          sizeBytes: item.sizeBytes,
          durationMs: Value(item.durationMs),
          format: item.format,
          origin: Value(origin),
          groupId: Value(item.groupId),
          groupIndex: Value(item.groupIndex),
          createdAt: item.createdAt,
        );
        await _database.libraryItemLocal.insertOne(row);
        return const SuccessState.nil();
      });

  @override
  FutureList<LibraryItem> getByIds(List<String> ids) => _errorHandler.execute(action: 'library.getByIds', () async {
    final table = _database.libraryItemLocal;
    final statement = table.select()..where((t) => t.id.isIn(ids));
    final rows = await statement.get();
    final items = rows.map(_toItem).toList();
    return SuccessState(data: items);
  });

  @override
  FutureVoid deleteByIds(List<String> ids) => _errorHandler.execute(action: 'library.deleteByIds', () async {
    final table = _database.libraryItemLocal;
    await (table.delete()..where((t) => t.id.isIn(ids))).go();
    return const SuccessState.nil();
  });

  @override
  Stream<List<LibraryItem>> watchAll() {
    final table = _database.libraryItemLocal;
    final statement = table.select()..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return statement.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  FutureVoid markSaved(String id, SaveDestination destination) =>
      _errorHandler.execute(action: 'library.markSaved', () async {
        final table = _database.libraryItemLocal;
        final now = Value(DateTime.now());
        await (table.update()..where((t) => t.id.equals(id))).write(switch (destination) {
          .photos => LibraryItemLocalCompanion(savedToPhotosAt: now),
          .files => LibraryItemLocalCompanion(savedToFilesAt: now),
        });
        return const SuccessState.nil();
      });

  static LibraryItem _toItem(LibraryItemLocalData row) => LibraryItem(
    id: row.id,
    kind: MediaKind.values.byName(row.kind),
    site: row.site == null ? null : Site.values.asNameMap()[row.site],
    title: row.title,
    uploader: row.uploader,
    sourceUrl: row.sourceUrl,
    relativePath: row.relativePath,
    thumbnailRelativePath: row.thumbnailRelativePath,
    sizeBytes: row.sizeBytes,
    durationMs: row.durationMs,
    format: row.format,
    createdAt: row.createdAt,
    savedToPhotosAt: row.savedToPhotosAt,
    savedToFilesAt: row.savedToFilesAt,
    groupId: row.groupId,
    groupIndex: row.groupIndex,
  );
}

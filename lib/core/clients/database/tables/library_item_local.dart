import 'package:drift/drift.dart';

/// One file in the Library. Paths are relative to AppDirectories.base.
class LibraryItemLocal extends Table {
  @override
  String get tableName => 'library_item';

  @override
  Set<Column<Object>> get primaryKey => {id};

  TextColumn get id => text()();

  /// MediaKind name: video / audio / photo.
  TextColumn get kind => text()();

  /// Site name, null for converted local files.
  TextColumn get site => text().nullable()();
  TextColumn get title => text()();
  TextColumn get uploader => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get relativePath => text()();
  TextColumn get thumbnailRelativePath => text().nullable()();
  IntColumn get sizeBytes => integer()();
  IntColumn get durationMs => integer().nullable()();

  /// File extension: mp4, mp3, jpg…
  TextColumn get format => text()();

  /// download / convert.
  TextColumn get origin => text().withDefault(const Constant('download'))();

  /// Shared by every item of one post (carousel); null for single files.
  TextColumn get groupId => text().nullable()();

  /// Position inside the group, from 0.
  IntColumn get groupIndex => integer().nullable()();
  DateTimeColumn get savedToPhotosAt => dateTime().nullable()();
  DateTimeColumn get savedToFilesAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

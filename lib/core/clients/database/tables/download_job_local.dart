import 'package:drift/drift.dart';

/// Jobs on the Download screen. Stage changes are stored, not every percent.
class DownloadJobLocal extends Table {
  @override
  String get tableName => 'download_job';

  @override
  Set<Column<Object>> get primaryKey => {id};

  TextColumn get id => text()();

  /// DownloadRequest as JSON (url, site, title, kind, quality…).
  TextColumn get request => text()();

  /// JobStage name.
  TextColumn get stage => text()();
  TextColumn get errorMessage => text().nullable()();

  /// JSON list of Library item ids, once done.
  TextColumn get libraryItemIds => text().withDefault(const Constant('[]'))();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}

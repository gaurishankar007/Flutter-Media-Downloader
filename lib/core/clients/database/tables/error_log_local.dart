import 'package:drift/drift.dart';

/// The last 500 recorded errors (see AppErrorRecorder).
class ErrorLogLocal extends Table {
  @override
  String get tableName => 'error_log';

  @override
  Set<Column<Object>> get primaryKey => {id};

  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Flow and operation labels, outermost first: `download.probe > engine.probe`.
  TextColumn get action => text().nullable()();

  /// The notifier that showed it.
  TextColumn get source => text().nullable()();
  TextColumn get message => text()();
  TextColumn get error => text().nullable()();
  BoolColumn get shown => boolean().withDefault(const Constant(false))();
}

import 'package:drift/drift.dart';

/// Generic key → JSON value store for settings and flags.
class KeyValueLocal extends Table {
  @override
  String get tableName => 'key_value';

  @override
  Set<Column<Object>> get primaryKey => {key};

  TextColumn get key => text()();
  TextColumn get value => text()();
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:media_downloader/core/clients/database/tables/download_job_local.dart';
import 'package:media_downloader/core/clients/database/tables/error_log_local.dart';
import 'package:media_downloader/core/clients/database/tables/key_value_local.dart';
import 'package:media_downloader/core/clients/database/tables/library_item_local.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The app's one local database. See docs/core/local_database.md.
// Schema 1 hasn't shipped yet, so it can still change in place. From the first
// release on, every change bumps schemaVersion with its own onUpgrade step.
@DriftDatabase(tables: [KeyValueLocal, ErrorLogLocal, LibraryItemLocal, DownloadJobLocal])
final class AppDatabase([QueryExecutor? executor]) extends _$AppDatabase {
  this : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (migrator) => migrator.createAll());

  static QueryExecutor _openConnection() => driftDatabase(
    name: 'media_downloader',
    native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
  );
}

/// Access to the [AppDatabase] singleton.
abstract final class AppDatabaseProvider {
  static AppDatabase get I => GetIt.I<AppDatabase>();

  static AppDatabase register() => GetIt.I.registerSingleton<AppDatabase>(AppDatabase());
}

# Local Database

> Status: planned. File: `lib/core/clients/database/app_database.dart`. Starting `schemaVersion`: `1`.

All on-device data lives in one drift (SQLite) database, `AppDatabase`. Media files themselves are **not** in the database: they're files in the app's folder (see [Core Services: Directories](core_services.md#app-directories)), and the database indexes them.

## Tables

| Table | Holds | Used by |
| --- | --- | --- |
| `LibraryItemLocal` | One row per file in the library: `id`, `kind` (video / audio / photo), `site`, `title`, `uploader`, `sourceUrl`, `relativePath`, `thumbnailRelativePath`, `sizeBytes`, `durationMs`, `width`, `height`, `format` (mp4, mp3, jpg…), `origin` (download / convert), `groupId` (all photos of one carousel), `groupIndex`, `savedToPhotosAt`, `savedToFilesAt`, `createdAt` | `LibraryLocalService` |
| `DownloadJobLocal` | Jobs shown on the Download screen: `id`, `url`, `site`, `title`, `thumbnailUrl`, request JSON (kind, quality, iPhone toggle, selected images), `stage`, `errorType`, `libraryItemIds` (JSON list, once done), `createdAt`, `finishedAt` | `JobLocalService` |
| `KeyValueLocal` | Settings and flags as key → JSON value (`settings`, `rightsNoticeAccepted`, `engineVersion`, `lastUpdateCheck`) | `SettingsLocalService` |
| `ErrorLogLocal` | Last 500 recorded errors | `AppErrorRecorder` |

Cookies are **not** in the database. They're cookies.txt files in a private folder (see [Settings: Cookies](../features/settings.md#cookies)).

### Paths are stored relative

Store paths relative to the app's base folder (`downloads/abc.mp4`), never absolute. On iOS the app container path changes between installs and updates, so an absolute path saved today can point nowhere tomorrow. `AppDirectories.resolve(relative)` turns it into a real path.

### Live queries

`LibraryLocalService.watchItems(filter)` and `JobLocalService.watchJobs()` return drift `Stream`s, so the Library grid and the job list update by themselves when a download finishes or an item is removed. They emit `DataState` (row-mapping errors arrive as `FailureState`, not a stream error).

## Local Service Method Style

Same as vAIolin: one step per variable.

```dart
Future<DataState<List<LibraryItem>>> getItems(LibraryFilter filter) =>
    _errorHandler.execute(action: 'library.getItems', () async {
      final table = _db.libraryItemLocal;
      // newest first, filtered by kind and site
      final statement = table.select()
        ..where((t) => filter.whereClause(t))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      final rows = await statement.get();
      final items = rows.map(LibraryItemMapper.fromRow).toList();
      return SuccessState(data: items);
    });
```

## Migrations

- Every `schemaVersion` bump gets its own `onUpgrade` step for that exact `from` → `to`. Never rely on drop-and-recreate: it would wipe the library index, leaving files on disk that the app no longer knows about.
- Every migration has an explicit `onUpgrade` step and a schema snapshot (`dart run drift_dev make-migrations`). Exported schema snapshots in `drift_schemas/` are committed and never deleted.

## Consistency Between Files and Rows

The database and the folder can drift apart (app killed mid-write, file deleted by the system). `LibraryRepository.reconcile()` runs once at startup, after the first frame:

- A row whose file is missing → row removed.
- A file in `downloads/` with no row and older than 1 hour → deleted (it's a leftover partial file).

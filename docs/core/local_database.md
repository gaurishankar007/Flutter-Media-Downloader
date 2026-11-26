# Local Database

> Status: built. Files: `lib/core/clients/database/app_database.dart`, `lib/core/clients/database/tables/`. `schemaVersion`: `1`.

All on-device data lives in one drift (SQLite) database, `AppDatabase` (file `media_downloader` in Application Support, opened with `drift_flutter`). Media files themselves are **not** in the database: they're files in the app's folder (see [Core Services: Directories](core_services.md#app-directories)), and the database indexes them.

## Tables

| Table (SQL name) | Holds | Used by |
| --- | --- | --- |
| `LibraryItemLocal` (`library_item`) | One row per file in the Library: `id`, `kind` (video / audio / photo), `site` (null for converted local files), `title`, `uploader`, `sourceUrl`, `relativePath`, `thumbnailRelativePath`, `sizeBytes`, `durationMs`, `format` (file extension: mp4, mp3, jpg…), `origin` (`download` / `convert`, default `download`), `groupId` (shared by every item of one multi-item post; null for single files), `groupIndex` (position in the group, from 0), `savedToPhotosAt`, `savedToFilesAt`, `createdAt` | `LibraryLocalService` |
| `DownloadJobLocal` (`download_job`) | Jobs shown on the Download screen: `id`, `request` (the `DownloadRequest` as JSON: url, site, title, kind, quality, iPhone toggle, chosen post media…), `stage` (`JobStage` name), `errorMessage`, `libraryItemIds` (JSON list, once done; default `[]`), `sizeBytes`, `createdAt`, `finishedAt`. Stage changes are stored, not every percent. | `JobLocalService` |
| `KeyValueLocal` (`key_value`) | Key → JSON value. Today one key, `settings`: the whole `AppSettings` (theme, rights notice accepted, ask-remove-after-save, default qualities, iPhone-compatible, photos to JPG, cookie browser, check engine on launch, last engine check time) | `SettingsLocalService` |
| `ErrorLogLocal` (`error_log`) | Last 500 recorded errors: `id`, `createdAt`, `action` (`download.probe > engine.probe`), `source` (the notifier that showed it), `message`, `error`, `shown` | `AppErrorRecorder`, `ErrorLogLocalService` (Settings → About → Error log) |

Cookies are **not** in the database. They're cookies.txt files in a private folder (see [Settings: Cookies](../features/settings.md#cookies)).

### Paths are stored relative

Store paths relative to the app's base folder (`downloads/abc.mp4`), never absolute. On iOS the app container path changes between installs and updates, so an absolute path saved today can point nowhere tomorrow. `AppDirectories.resolve(relative)` turns it into a real path; `AppDirectories.relative(absolute)` goes the other way before an insert.

### Live queries

`LibraryLocalService.watchAll()` returns a drift `Stream` of every item, newest first. It isn't filtered: `LibraryRepository.watchItems()` wraps it in `DataState` (a stream error becomes one recorded `FailureState`), and the Library notifier filters, searches, sorts and groups in memory. The Library grid therefore updates by itself when a download finishes or an item is removed.

Jobs aren't watched: `DownloadQueueNotifier` (keep-alive) holds them in memory and `JobLocalService` only loads them at startup (`getAll`), saves stage changes (`save`) and deletes cleared ones (`deleteByIds`). Jobs that were still running when the app was killed come back as failed with "The app was closed during this download."

## Local Service Method Style

One step per variable, every call inside `ErrorHandler.execute` with an `action:` label.

```dart
FutureList<LibraryItem> getByIds(List<String> ids) => _errorHandler.execute(action: 'library.getByIds', () async {
  final table = _database.libraryItemLocal;
  final statement = table.select()..where((t) => t.id.isIn(ids));
  final rows = await statement.get();
  final items = rows.map(_toItem).toList();
  return SuccessState(data: items);
});
```

## Migrations

- Schema 1 hasn't shipped, so it is still changed **in place** (that's how `groupId` / `groupIndex` and `origin` were added). The `MigrationStrategy` only has `onCreate: createAll()`. There is no `drift_schemas/` folder yet.
- From the first release on, every `schemaVersion` bump gets its own `onUpgrade` step for that exact `from` → `to` and an exported schema snapshot (`dart run drift_dev make-migrations`). Never rely on drop-and-recreate: it would wipe the Library index, leaving files on disk that the app no longer knows about. Exported snapshots are committed and never deleted.

## Consistency Between Files and Rows

The database and the folder can drift apart (app killed mid-write, file deleted by the system).

- `AppDirectories.init()` deletes the whole `work/` folder at startup, so partial downloads and ffmpeg intermediates from a killed run never pile up.
- There is no startup reconcile pass yet: a row whose file went missing stays in the Library until it's deleted there.

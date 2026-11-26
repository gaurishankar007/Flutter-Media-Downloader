import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/download_request.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/job_stage.dart';

abstract interface class JobLocalService {
  /// All jobs, newest first.
  FutureList<DownloadJob> getAll();

  /// Inserts or replaces [job] with its current stage.
  FutureVoid save(DownloadJob job);

  FutureVoid deleteByIds(List<String> ids);
}

@LazySingleton(as: JobLocalService)
final class JobLocalServiceImpl({required final AppDatabase _database, required final ErrorHandler _errorHandler})
    implements JobLocalService {
  @override
  FutureList<DownloadJob> getAll() => _errorHandler.execute(action: 'jobs.getAll', () async {
    final table = _database.downloadJobLocal;
    final statement = table.select()..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await statement.get();
    final jobs = rows.map(_toJob).toList();
    return SuccessState(data: jobs);
  });

  @override
  FutureVoid save(DownloadJob job) => _errorHandler.execute(action: 'jobs.save', () async {
    final progress = job.progress;
    final row = DownloadJobLocalCompanion.insert(
      id: job.id,
      request: jsonEncode(job.request.toJson()),
      stage: job.stage.name,
      errorMessage: Value(progress.errorMessage),
      libraryItemIds: Value(jsonEncode(progress.libraryItemIds)),
      sizeBytes: Value(progress.sizeBytes),
      createdAt: job.createdAt,
      finishedAt: Value(job.stage.isFinished ? DateTime.now() : null),
    );
    await _database.downloadJobLocal.insertOnConflictUpdate(row);
    return const SuccessState.nil();
  });

  @override
  FutureVoid deleteByIds(List<String> ids) => _errorHandler.execute(action: 'jobs.deleteByIds', () async {
    final table = _database.downloadJobLocal;
    await (table.delete()..where((t) => t.id.isIn(ids))).go();
    return const SuccessState.nil();
  });

  static DownloadJob _toJob(DownloadJobLocalData row) => DownloadJob(
    id: row.id,
    request: DownloadRequest.fromJson(jsonDecode(row.request) as JsonMap),
    createdAt: row.createdAt,
    progress: JobProgress(
      stage: JobStage.values.asNameMap()[row.stage] ?? .failed,
      errorMessage: row.errorMessage,
      libraryItemIds: (jsonDecode(row.libraryItemIds) as List<dynamic>).cast<String>(),
      sizeBytes: row.sizeBytes,
    ),
  );
}

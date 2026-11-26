import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';

/// Reads the local error log (`ErrorLogLocal`) that AppErrorRecorder writes.
abstract interface class ErrorLogLocalService {
  /// Every entry as one line of text, newest first.
  FutureList<String> readLines();
}

@LazySingleton(as: ErrorLogLocalService)
final class ErrorLogLocalServiceImpl({required final AppDatabase _database, required final ErrorHandler _errorHandler})
    implements ErrorLogLocalService {
  @override
  FutureList<String> readLines() => _errorHandler.execute(action: 'errorLog.read', () async {
    final table = _database.errorLogLocal;
    final rows = await (table.select()..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return SuccessState(
      data: [
        for (final row in rows)
          [
            row.createdAt.toIso8601String(),
            if (row.shown) 'shown' else 'hidden',
            ?row.action,
            ?row.source,
            row.message,
            if (row.error case final error? when error != row.message) error,
          ].join(' | '),
      ],
    );
  });
}

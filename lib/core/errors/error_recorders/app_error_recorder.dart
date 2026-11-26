import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_recorders/error_recorder.dart';
import 'package:uuid/uuid.dart';

/// Keeps the last [_maxEntries] errors in the local error log (`ErrorLogLocal`),
/// marking the ones the user was shown. Nothing leaves the device.
final class AppErrorRecorder({required final AppDatabase _database}) implements ErrorRecorder {
  static const _maxEntries = 500;
  static final _urlQuery = RegExp(r'(https?://[^\s?#]+)[?#]\S*');

  @override
  void recordUncaughtErrors() {
    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterOnError?.call(details);
      _insert(message: details.exceptionAsString(), error: details.exception.toString(), shown: false);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _insert(message: error.toString(), error: error.toString(), shown: false);
      return true;
    };
  }

  @override
  bool get isRecordable => true;

  @override
  void record({required Object error, FailureState<dynamic>? failureState, StackTrace? stackTrace}) => _insert(
    id: failureState?.errorId,
    action: failureState?.actionPath.join(' > '),
    message: failureState?.message ?? error.toString(),
    error: failureState?.error ?? error.toString(),
    shown: false,
  );

  /// Marks a failure the user is shown; [action] is the user's flow.
  void trackFailure(DataState<dynamic> dataState, {String? action, String? source}) {
    if (dataState is! FailureState) {
      return;
    }
    final path = dataState.withAction(action).actionPath.join(' > ');
    if (dataState.errorId case final errorId?) {
      unawaited(
        _safely(
          () => (_database.update(_database.errorLogLocal)..where((t) => t.id.equals(errorId))).write(
            ErrorLogLocalCompanion(action: Value(path), source: Value(source), shown: const Value(true)),
          ),
        ),
      );
      return;
    }
    _insert(action: path, source: source, message: dataState.message ?? '', error: dataState.error, shown: true);
  }

  /// Logs a notifier-side error (validation, guards) the user is shown.
  void trackError(String text, {String? action, String? source}) =>
      _insert(action: action, source: source, message: text, shown: true);

  void _insert({
    required String message,
    required bool shown,
    String? id,
    String? action,
    String? source,
    String? error,
  }) => unawaited(
    _safely(() async {
      await _database
          .into(_database.errorLogLocal)
          .insertOnConflictUpdate(
            ErrorLogLocalCompanion.insert(
              id: id ?? const Uuid().v4(),
              createdAt: DateTime.now(),
              action: Value(action),
              source: Value(source),
              message: _stripQueries(message),
              error: Value(error == null ? null : _stripQueries(error)),
              shown: Value(shown),
            ),
          );
      await _database.customStatement(
        'DELETE FROM error_log WHERE id NOT IN (SELECT id FROM error_log ORDER BY created_at DESC LIMIT $_maxEntries)',
      );
    }),
  );

  // URLs can carry tokens in their query, so the log keeps only the path.
  static String _stripQueries(String text) => text.replaceAllMapped(_urlQuery, (match) => match.group(1)!);

  // Never let the error log throw: that would loop back into the recorder.
  static Future<void> _safely(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      debugPrint('AppErrorRecorder: $error');
    }
  }
}

/// Access to the [AppErrorRecorder] singleton.
abstract final class AppErrorProvider {
  static AppErrorRecorder get I => GetIt.I<AppErrorRecorder>();

  static void register(AppDatabase database) =>
      GetIt.I.registerSingleton<AppErrorRecorder>(AppErrorRecorder(database: database));
}

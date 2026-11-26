import 'package:get_it/get_it.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_recorders/error_recorder.dart';
import 'package:media_tool/core/errors/error_translators/error_translator.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:uuid/uuid.dart';

abstract interface class ErrorHandler {
  /// Hooks every recorder into uncaught errors.
  void configureErrorHandlers();

  /// Runs [callBack]; a thrown error becomes a recorded [FailureState].
  /// [action] names the exact operation, e.g. `'settings.save'`.
  FutureData<T> execute<T>(FutureData<T> Function() callBack, {required String action});

  /// Runs [callBack], recording (not rethrowing) any error.
  Future<void> executeSafe(Future<void> Function() callBack);

  /// Runs [callBack], recording any error and returning [onError]'s value instead.
  Future<T> executeSafeReturn<T>(Future<T> Function() callBack, {required T Function(Object error) onError});
}

final class ErrorHandlerImpl({
  required final List<ErrorTranslator> _errorTranslators,
  required final List<ErrorRecorder> _errorRecorders,
}) implements ErrorHandler {
  @override
  void configureErrorHandlers() {
    for (final recorder in _errorRecorders) {
      recorder.recordUncaughtErrors();
    }
  }

  @override
  FutureData<T> execute<T>(FutureData<T> Function() callBack, {required String action}) async {
    try {
      final result = await callBack();
      if (result case final FailureState<T> failure) {
        return failure.withAction(action).withStackTrace(StackTrace.current);
      }
      return result;
    } catch (error, stackTrace) {
      final failure = _translate<T>(error).withAction(action).withStackTrace(stackTrace).withErrorId(const Uuid().v4());
      _record(error: error, failureState: failure, stackTrace: stackTrace);
      return failure;
    }
  }

  @override
  Future<void> executeSafe(Future<void> Function() callBack) async {
    try {
      await callBack();
    } catch (error, stackTrace) {
      _record(error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<T> executeSafeReturn<T>(Future<T> Function() callBack, {required T Function(Object error) onError}) async {
    try {
      return await callBack();
    } catch (error, stackTrace) {
      _record(error: error, stackTrace: stackTrace);
      return onError(error);
    }
  }

  void _record({required Object error, FailureState<dynamic>? failureState, StackTrace? stackTrace}) {
    for (final recorder in _errorRecorders) {
      if (recorder.isRecordable) {
        recorder.record(error: error, failureState: failureState, stackTrace: stackTrace);
      }
    }
  }

  FailureState<T> _translate<T>(Object error) {
    for (final translator in _errorTranslators) {
      if (translator.matches(error)) {
        return translator.translate<T>(error);
      }
    }
    return FailureState<T>(error: error.toString());
  }
}

/// Access to the [ErrorHandler] singleton.
abstract final class ErrorHandlerProvider {
  static ErrorHandler get I => GetIt.I<ErrorHandler>();

  static void register({
    List<ErrorTranslator<Object>> errorTranslators = const [],
    List<ErrorRecorder> errorRecorders = const [],
  }) => GetIt.I.registerLazySingleton<ErrorHandler>(
    () => ErrorHandlerImpl(errorTranslators: errorTranslators, errorRecorders: errorRecorders),
  );
}

part of 'data_state.dart';

/// A failed operation.
final class const FailureState<T>({
  String? message,
  super.error,

  /// The labelled levels the failure passed through, outermost first
  /// (e.g. `['download.probe', 'engine.probe']`). Kept out of equality.
  final List<String> actionPath = const [],

  /// Where the failure happened. Kept out of equality.
  final StackTrace? stackTrace,

  /// The error log entry this failure was recorded under, so showing it
  /// marks that entry instead of adding a duplicate. Kept out of equality.
  final String? errorId,
}) extends DataState<T> {
  this : super(message: message ?? CommonMessages.genericError, hasError: true);

  /// Returns a copy with [action] as the outermost level; skipped when null
  /// or equal to the current outermost level.
  FailureState<T> withAction(String? action) {
    if (action == null || actionPath.firstOrNull == action) {
      return this;
    }
    return _copyWith(actionPath: [action, ...actionPath]);
  }

  /// Returns a copy with [stackTrace], keeping an existing (closer) one.
  FailureState<T> withStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null || this.stackTrace != null) {
      return this;
    }
    return _copyWith(stackTrace: stackTrace);
  }

  /// Returns a copy linked to the logged error [errorId].
  FailureState<T> withErrorId(String errorId) => _copyWith(errorId: errorId);

  /// Returns this failure typed for another result, keeping every field.
  FailureState<R> retype<R>() =>
      FailureState<R>(message: message, error: error, actionPath: actionPath, stackTrace: stackTrace, errorId: errorId);

  FailureState<T> _copyWith({List<String>? actionPath, StackTrace? stackTrace, String? errorId}) => FailureState<T>(
    message: message,
    error: error,
    actionPath: actionPath ?? this.actionPath,
    stackTrace: stackTrace ?? this.stackTrace,
    errorId: errorId ?? this.errorId,
  );
}

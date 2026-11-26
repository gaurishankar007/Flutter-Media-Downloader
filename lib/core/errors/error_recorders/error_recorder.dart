import 'package:media_tool/core/data/states/data_state.dart';

/// Records errors to one channel (console, local error log).
abstract interface class ErrorRecorder {
  /// Hooks into uncaught Flutter and platform errors.
  void recordUncaughtErrors();

  /// Whether [record] should run at all.
  bool get isRecordable;

  void record({required Object error, FailureState<dynamic>? failureState, StackTrace? stackTrace});
}

import 'package:media_tool/core/data/states/data_state.dart';

/// Translates a thrown error into a [FailureState].
abstract interface class ErrorTranslator<E extends Object> {
  /// Whether this translator handles [error].
  bool matches(Object error);

  FailureState<T> translate<T>(E error);
}

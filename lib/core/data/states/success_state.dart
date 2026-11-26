part of 'data_state.dart';

/// A finished operation with its data.
final class SuccessState<T> extends DataState<T> {
  const new({required super.data, super.message}) : super(hasData: true);

  /// Success with no payload, for `FutureVoid` methods.
  const new nil() : super(data: null, hasData: true);
}

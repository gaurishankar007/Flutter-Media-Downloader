import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:media_downloader/core/messages/app_messages.dart';

part 'failure_state.dart';
part 'loading_state.dart';
part 'success_state.dart';

/// Sealed state of an async data operation: [SuccessState], [FailureState] or [LoadingState].
@immutable
sealed class const DataState<T>({
  /// The payload of a successful operation.
  final T? data,

  /// A user-facing message.
  final String? message,

  /// A raw error string for the error log, not for display.
  final String? error,
  final bool hasData = false,
  final bool hasError = false,
}) extends Equatable {
  /// Transforms `data` from `T` to `R`, keeping failures and loading as-is but typed to `R`.
  DataState<R> mapData<R>(R Function(T data) transform) => switch (this) {
    SuccessState(:final data) => SuccessState<R>(data: transform(data as T), message: message),
    final FailureState<T> failure => failure.retype<R>(),
    LoadingState() => LoadingState<R>(),
  };

  @override
  List<Object?> get props => [data, message, error, hasData, hasError];
}

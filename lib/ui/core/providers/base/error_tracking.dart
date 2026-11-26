part of 'base_notifier.dart';

/// Logs the errors a notifier shows the user in the error log.
mixin ErrorTracking {
  /// Runs [call] as the user flow [action], so data-layer errors inside it
  /// are labelled with the flow and this notifier.
  T runFlow<T>(String action, T Function() call) => ErrorFlow(action: action, source: '$runtimeType').run(call);

  /// Logs a notifier-side error (validation) as shown and returns it as an [ErrorMessage].
  ErrorMessage trackError(String text, {String? action}) {
    AppErrorProvider.I.trackError(text, action: _flowAction(action), source: '$runtimeType');
    return ErrorMessage(text);
  }

  /// Marks a failed [dataState] as shown and returns its message as an [ErrorMessage].
  ErrorMessage trackFailure(DataState<dynamic> dataState, {String? action}) {
    AppErrorProvider.I.trackFailure(dataState, action: _flowAction(action), source: '$runtimeType');
    return ErrorMessage(dataState.message ?? '');
  }

  String? _flowAction(String? action) {
    final flowAction = action ?? ErrorFlow.current?.action;
    assert(flowAction != null, 'Track errors inside runFlow or pass an action, so the log names the flow.');
    return flowAction;
  }
}

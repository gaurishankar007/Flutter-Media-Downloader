part of 'base_notifier.dart';

/// Where a screen is: idle, loading, loaded, error, or refreshing (loaded
/// data on screen while new data loads).
enum StateStatus { idle, loading, loaded, error, refreshing }

/// A one-shot message the View shows with `ToastUtil`, carried on
/// [BaseState.message]. Equal by text, so `listenMessages` doesn't repeat a
/// message that is still set while other fields change.
sealed class const StateMessage(final String text) extends Equatable {
  @override
  List<Object?> get props => [text];
}

class const SuccessMessage(super.text) extends StateMessage;

class const ErrorMessage(super.text) extends StateMessage;

class const WarningMessage(super.text) extends StateMessage;

/// Neutral information (neither success, error nor warning).
class const NormalMessage(super.text) extends StateMessage;

/// Base state for notifiers. A subclass's `copyWith` takes `message` as given
/// (never `?? this.message`), so a message can be cleared.
abstract class const BaseState({final StateStatus status = .idle, final StateMessage? message}) extends Equatable {
  bool get isLoading => status == .loading;

  @override
  List<Object?> get props => [status, message];
}

part of 'base_notifier.dart';

/// The status of a view/notifier.
enum StateStatus { idle, loading, loaded, error, refreshing }

/// A message for the View to show (as a toast).
sealed class const StateMessage(final String text);

class const SuccessMessage(super.text) extends StateMessage;

class const ErrorMessage(super.text) extends StateMessage;

class const WarningMessage(super.text) extends StateMessage;

class const NormalMessage(super.text) extends StateMessage;

/// Base state for notifiers. A subclass's `copyWith` takes `message` as given
/// (never `?? this.message`), so a message can be cleared.
abstract class const BaseState({final StateStatus status = .idle, final StateMessage? message}) extends Equatable {
  @override
  List<Object?> get props => [status, message];
}

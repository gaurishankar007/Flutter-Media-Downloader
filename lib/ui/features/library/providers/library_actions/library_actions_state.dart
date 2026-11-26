part of 'library_actions_notifier.dart';

/// Items just saved to [destination], waiting for the View's "remove from app?" prompt.
final class const PendingRemovePrompt({required final List<String> ids, required final SaveDestination destination})
    extends Equatable {
  @override
  List<Object?> get props => [ids, destination];
}

final class const LibraryActionsState({
  /// Items with a save in flight.
  final Set<String> busyIds = const {},
  final PendingRemovePrompt? pendingRemovePrompt,
  super.status,
  super.message,
}) extends BaseState {
  LibraryActionsState copyWith({
    Set<String>? busyIds,
    PendingRemovePrompt? pendingRemovePrompt,
    bool clearPrompt = false,
    StateStatus? status,
    StateMessage? message,
  }) => LibraryActionsState(
    busyIds: busyIds ?? this.busyIds,
    pendingRemovePrompt: clearPrompt ? null : pendingRemovePrompt ?? this.pendingRemovePrompt,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [busyIds, pendingRemovePrompt, ...super.props];
}

part of 'storage_notifier.dart';

final class const StorageState({final StorageUsage? usage, final bool clearing = false, super.status, super.message})
    extends BaseState {
  StorageState copyWith({StorageUsage? usage, bool? clearing, StateStatus? status, StateMessage? message}) =>
      StorageState(
        usage: usage ?? this.usage,
        clearing: clearing ?? this.clearing,
        status: status ?? this.status,
        message: message,
      );

  @override
  List<Object?> get props => [usage, clearing, ...super.props];
}

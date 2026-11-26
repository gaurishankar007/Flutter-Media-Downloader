part of 'settings_notifier.dart';

final class const SettingsState({required final AppSettings settings, super.status, super.message}) extends BaseState {
  SettingsState copyWith({AppSettings? settings, StateStatus? status, StateMessage? message}) =>
      SettingsState(settings: settings ?? this.settings, status: status ?? this.status, message: message);

  @override
  List<Object?> get props => [settings, ...super.props];
}

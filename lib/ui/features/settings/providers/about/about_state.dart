part of 'about_notifier.dart';

final class const AboutState({final String? appVersion, super.status, super.message}) extends BaseState {
  AboutState copyWith({String? appVersion, StateStatus? status, StateMessage? message}) =>
      AboutState(appVersion: appVersion ?? this.appVersion, status: status ?? this.status, message: message);

  @override
  List<Object?> get props => [appVersion, ...super.props];
}

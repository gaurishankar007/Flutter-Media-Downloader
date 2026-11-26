part of 'engine_status_notifier.dart';

enum EngineStatus { initializing, ready, failed }

/// What the engine's update button is doing.
enum EngineUpdateStatus { idle, checking, updating }

final class const EngineStatusState({
  final EngineStatus engineStatus = .initializing,
  final EngineInfo? info,
  final String? errorText,
  final EngineUpdateStatus updateStatus = .idle,

  /// The latest release, once a check found one newer than [info]'s.
  final String? availableVersion,
  super.status,
  super.message,
}) extends BaseState {
  bool get updateAvailable => availableVersion != null;

  EngineStatusState copyWith({
    EngineStatus? engineStatus,
    EngineInfo? info,
    String? errorText,
    EngineUpdateStatus? updateStatus,
    String? availableVersion,
    bool clearAvailableVersion = false,
    StateStatus? status,
    StateMessage? message,
  }) => EngineStatusState(
    engineStatus: engineStatus ?? this.engineStatus,
    info: info ?? this.info,
    errorText: errorText ?? this.errorText,
    updateStatus: updateStatus ?? this.updateStatus,
    availableVersion: clearAvailableVersion ? null : availableVersion ?? this.availableVersion,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [engineStatus, info, errorText, updateStatus, availableVersion, ...super.props];
}

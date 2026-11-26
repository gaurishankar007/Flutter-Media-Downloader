part of 'system_monitor_notifier.dart';

final class const SystemMonitorState({
  /// What this device reports, in display order. Empty hides the monitor.
  final List<SystemMetric> metrics = const [],

  /// False until the platform said what it supports.
  final bool metricsKnown = false,
  final SystemSample? latest,

  /// Oldest first, at most [SystemMonitorNotifier.historyLength].
  final List<SystemSample> history = const [],

  /// Read every few seconds; null until the first reading.
  final DeviceStorage? storage,
  final BatteryStatus? battery,
  super.status,
  super.message,
}) extends BaseState {
  SystemMonitorState copyWith({
    List<SystemMetric>? metrics,
    bool? metricsKnown,
    SystemSample? latest,
    List<SystemSample>? history,
    DeviceStorage? storage,
    BatteryStatus? battery,
    StateStatus? status,
    StateMessage? message,
  }) => SystemMonitorState(
    metrics: metrics ?? this.metrics,
    metricsKnown: metricsKnown ?? this.metricsKnown,
    latest: latest ?? this.latest,
    history: history ?? this.history,
    storage: storage ?? this.storage,
    battery: battery ?? this.battery,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [metrics, metricsKnown, latest, history, storage, battery, ...super.props];
}

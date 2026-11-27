part of 'system_monitor_notifier.dart';

final class const SystemMonitorState({
  /// What this device shows, in display order. Empty hides the monitor.
  final List<SystemMetric> metrics = const [],

  /// The metrics with a live reading; the rest show hardware facts only.
  final Set<SystemMetric> liveMetrics = const {},

  /// False until the platform said what it supports.
  final bool metricsKnown = false,
  final DeviceHardware? hardware,
  final SystemSample? latest,

  /// Oldest first, at most [SystemMonitorNotifier.historyLength].
  final List<SystemSample> history = const [],

  /// Read every few seconds; null until the first reading.
  final DeviceStorage? storage,
  final BatteryStatus? battery,

  /// The latest result of each speed test run in this app session.
  final Map<SpeedTest, SpeedTestResult> speedResults = const {},

  /// The speed test running now (one at a time).
  final SpeedTest? runningTest,
  super.status,
  super.message,
}) extends BaseState {
  SystemMonitorState copyWith({
    List<SystemMetric>? metrics,
    Set<SystemMetric>? liveMetrics,
    bool? metricsKnown,
    DeviceHardware? hardware,
    SystemSample? latest,
    List<SystemSample>? history,
    DeviceStorage? storage,
    BatteryStatus? battery,
    Map<SpeedTest, SpeedTestResult>? speedResults,
    SpeedTest? runningTest,
    bool clearRunningTest = false,
    StateStatus? status,
    StateMessage? message,
  }) => SystemMonitorState(
    metrics: metrics ?? this.metrics,
    liveMetrics: liveMetrics ?? this.liveMetrics,
    metricsKnown: metricsKnown ?? this.metricsKnown,
    hardware: hardware ?? this.hardware,
    latest: latest ?? this.latest,
    history: history ?? this.history,
    storage: storage ?? this.storage,
    battery: battery ?? this.battery,
    speedResults: speedResults ?? this.speedResults,
    runningTest: clearRunningTest ? null : runningTest ?? this.runningTest,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [
    metrics,
    liveMetrics,
    metricsKnown,
    hardware,
    latest,
    history,
    storage,
    battery,
    speedResults,
    runningTest,
    ...super.props,
  ];
}

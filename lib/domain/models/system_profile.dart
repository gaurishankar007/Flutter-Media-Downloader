import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/device_hardware.dart';
import 'package:media_tool/domain/models/system_metric.dart';

/// What the System page shows on this device: the cards in display order,
/// which of them have a live reading, and the fixed hardware facts.
final class const SystemProfile({
  required final List<SystemMetric> metrics,

  /// Cards with a live load. A card in [metrics] but not here shows hardware
  /// facts only (CPU on Android, GPU on iOS).
  required final Set<SystemMetric> liveMetrics,
  final DeviceHardware? hardware,
}) extends Equatable {
  @override
  List<Object?> get props => [metrics, liveMetrics, hardware];
}

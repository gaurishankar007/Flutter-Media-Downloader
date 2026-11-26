import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/battery_charge_state.dart';
import 'package:media_tool/domain/models/battery_health.dart';

/// The battery at one moment. Extras are null where the platform doesn't
/// report them: temperature and health (Android), time remaining and
/// [healthPercent] (macOS), [cycleCount] (macOS, Android 14+ on some devices).
final class const BatteryStatus({
  required final double levelPercent,
  required final BatteryChargeState state,
  final double? temperatureCelsius,
  final BatteryHealth? health,
  final int? minutesRemaining,

  /// Full-charge capacity as a share of design capacity, 0–100.
  final double? healthPercent,
  final int? cycleCount,
}) extends Equatable {
  @override
  List<Object?> get props => [
    levelPercent,
    state,
    temperatureCelsius,
    health,
    minutesRemaining,
    healthPercent,
    cycleCount,
  ];
}

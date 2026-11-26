/// Whether the battery is charging.
enum BatteryChargeState {
  charging,
  full,
  discharging,

  /// Plugged in but not charging (e.g. held at a charge limit).
  notCharging,
  unknown,
}

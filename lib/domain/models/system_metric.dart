/// A live device stat the System monitor can show. Each platform supports
/// only some; unsupported ones are never shown. Declaration order is the
/// order of the System page cards.
enum SystemMetric {
  /// Whole-device download and upload speed.
  network,

  /// Charge level and state, plus health and cycles where the platform reports
  /// them (hidden on devices without a battery).
  battery,

  /// RAM used / total.
  memory,

  /// Whole-device CPU load (iOS, macOS).
  cpu,

  /// GPU utilization (macOS).
  gpu,

  /// Used / free space of the volume holding the app's files, and the app's share.
  storage,
}

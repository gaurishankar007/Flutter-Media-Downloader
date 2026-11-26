/// A live device stat the System monitor can show. Each platform supports
/// only some; unsupported ones are never shown.
enum SystemMetric {
  /// RAM used / total.
  memory,

  /// Whole-device CPU load (iOS, macOS).
  cpu,

  /// GPU utilization (macOS).
  gpu,

  /// Whole-device download and upload speed.
  network,
}

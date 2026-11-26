// Pigeon input: keeps classic field + constructor syntax (see CLAUDE.md).
// Regenerate: dart run pigeon --input lib/config/pigeon/system_monitor_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/clients/platform/system_monitor_api.g.dart',
    dartPackageName: 'media_downloader',
    kotlinOut: 'android/app/src/main/kotlin/com/example/media_downloader/system/SystemMonitorApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.media_downloader.system'),
    swiftOut: [
      'ios/Runner/SystemMonitor/SystemMonitorApi.g.swift',
      'macos/Runner/SystemMonitor/SystemMonitorApi.g.swift',
    ],
    // Own error class name, so it never clashes with another Pigeon file in the same target.
    swiftOptions: SwiftOptions(errorClassName: 'SystemMonitorPigeonError'),
  ),
)
/// Which metrics this device can report. Only these are shown.
class SystemCapabilitiesMsg {
  SystemCapabilitiesMsg({required this.memory, required this.cpu, required this.gpu, required this.network});

  bool memory;

  /// Whole-device CPU load (iOS, macOS).
  bool cpu;

  /// GPU utilization (macOS).
  bool gpu;

  /// Whole-device network traffic.
  bool network;
}

/// Raw counters at one moment. Dart turns two samples into rates; native
/// code keeps no state. Fields are null where the metric isn't supported.
class SystemSampleMsg {
  SystemSampleMsg({
    required this.uptimeMillis,
    this.memoryUsedBytes,
    this.memoryTotalBytes,
    this.cpuBusyTicks,
    this.cpuTotalTicks,
    this.gpuPercent,
    this.networkRxBytes,
    this.networkTxBytes,
  });

  /// Monotonic clock (time since boot), for the delta between samples.
  int uptimeMillis;

  int? memoryUsedBytes;
  int? memoryTotalBytes;

  /// Cumulative CPU ticks across all cores: busy (user + system + nice) and total (busy + idle).
  int? cpuBusyTicks;
  int? cpuTotalTicks;

  /// Instant GPU utilization, 0–100.
  double? gpuPercent;

  /// Cumulative bytes received / sent by all non-loopback interfaces.
  int? networkRxBytes;
  int? networkTxBytes;
}

/// Device stats for the System monitor. Nothing leaves the device.
@HostApi()
abstract class SystemMonitorHostApi {
  SystemCapabilitiesMsg capabilities();

  SystemSampleMsg sample();
}

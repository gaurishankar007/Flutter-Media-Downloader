// Pigeon input: keeps classic field + constructor syntax (see CLAUDE.md).
// Regenerate: dart run pigeon --input lib/config/pigeon/system_monitor_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/clients/platform/system_monitor_api.g.dart',
    dartPackageName: 'media_tool',
    kotlinOut: 'android/app/src/main/kotlin/com/gss/mediatool/system/SystemMonitorApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.gss.mediatool.system'),
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
  SystemCapabilitiesMsg({
    required this.memory,
    required this.cpu,
    required this.gpu,
    required this.network,
    required this.storage,
    required this.battery,
  });

  bool memory;

  /// Whole-device CPU load (iOS, macOS).
  bool cpu;

  /// GPU utilization (macOS).
  bool gpu;

  /// Whole-device network traffic.
  bool network;

  /// Total and free space of the volume holding the app's files.
  bool storage;

  /// A battery is present and reports its level (false on desktop Macs and simulators).
  bool battery;
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

/// Space on the volume holding the app's files. Null when it can't be read.
class SystemStorageMsg {
  SystemStorageMsg({this.totalBytes, this.freeBytes});

  int? totalBytes;

  /// Space apps can still use (iOS/macOS: "available for important usage").
  int? freeBytes;
}

enum BatteryStateMsg { charging, full, discharging, notCharging, unknown }

enum BatteryHealthMsg { good, overheat, dead, overVoltage, failure, cold, unknown }

/// The battery right now. [levelPercent] null means there's no battery data.
class SystemBatteryMsg {
  SystemBatteryMsg({
    this.levelPercent,
    required this.state,
    this.temperatureCelsius,
    this.health,
    this.minutesRemaining,
    this.healthPercent,
    this.cycleCount,
  });

  /// Charge, 0–100.
  double? levelPercent;

  BatteryStateMsg state;

  /// Android only.
  double? temperatureCelsius;

  /// Android only.
  BatteryHealthMsg? health;

  /// macOS only: minutes until empty (discharging) or full (charging).
  int? minutesRemaining;

  /// macOS only: full-charge capacity as a share of design capacity, 0–100.
  double? healthPercent;

  /// Charge cycles so far (macOS; Android 14+ where the device reports it).
  int? cycleCount;

  /// macOS only: capacity the battery was built with, in mAh.
  int? designCapacityMah;

  /// macOS only: what a full charge holds now, in mAh.
  int? fullChargeCapacityMah;

  /// Charge left in mAh (macOS; Android where the fuel gauge reports it).
  int? remainingCapacityMah;
}

/// Fixed hardware facts, read once. Every field is null where the platform
/// doesn't tell apps.
class SystemHardwareMsg {
  SystemHardwareMsg({
    this.cpuName,
    this.cpuCores,
    this.cpuThreads,
    this.cpuClusterCores,
    this.cpuMaxFrequencyMhz,
    this.gpuName,
    this.gpuCores,
    this.memoryType,
    this.memoryManufacturer,
    this.memorySpeedMhz,
    this.storageModel,
    this.storageSolidState,
    this.storageNvme,
    this.storageInterface,
  });

  /// "Apple M4 Pro" (macOS), "Apple A16" (iOS, from the GPU name), "QTI SM8550" (Android 12+).
  String? cpuName;

  /// Physical cores.
  int? cpuCores;

  /// Logical CPUs (more than [cpuCores] only with hyper-threading, e.g. Intel Macs).
  int? cpuThreads;

  /// Cores per cluster, fastest first (Apple: performance, efficiency; Android: by max clock).
  List<int>? cpuClusterCores;

  /// Android only: the fastest core's max clock.
  int? cpuMaxFrequencyMhz;

  /// "Apple M4 Pro" (macOS IOAccelerator), "Apple A16 GPU" (iOS Metal).
  String? gpuName;

  /// macOS (Apple silicon) only.
  int? gpuCores;

  /// macOS only: "LPDDR5", "DDR4".
  String? memoryType;

  /// macOS only.
  String? memoryManufacturer;

  /// macOS (Intel) only.
  int? memorySpeedMhz;

  /// macOS only: the drive holding the app's files.
  String? storageModel;
  bool? storageSolidState;
  bool? storageNvme;

  /// macOS only: "Apple Fabric", "PCI-Express", "SATA".
  String? storageInterface;
}

/// Device stats for the System monitor. Nothing leaves the device.
@HostApi()
abstract class SystemMonitorHostApi {
  SystemCapabilitiesMsg capabilities();

  SystemSampleMsg sample();

  SystemStorageMsg storage();

  SystemBatteryMsg battery();

  /// Slow on macOS (runs system_profiler), so off the main thread.
  @async
  SystemHardwareMsg hardware();
}

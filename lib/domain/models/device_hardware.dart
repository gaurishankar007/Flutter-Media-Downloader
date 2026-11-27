import 'package:equatable/equatable.dart';

/// Fixed hardware facts, read once. Each field is null where the platform
/// doesn't tell apps (RAM type, GPU cores and the drive are macOS only).
final class const DeviceHardware({
  final String? cpuName,
  final int? cpuCores,
  final int? cpuThreads,

  /// Cores per cluster, fastest first, e.g. `[8, 4]` (performance, efficiency).
  final List<int> cpuClusterCores = const [],
  final int? cpuMaxFrequencyMhz,
  final String? gpuName,
  final int? gpuCores,
  final String? memoryType,
  final String? memoryManufacturer,
  final int? memorySpeedMhz,
  final String? storageModel,
  final bool? storageSolidState,
  final bool? storageNvme,

  /// How the drive is attached: "Apple Fabric", "PCI-Express", "SATA".
  final String? storageInterface,
}) extends Equatable {
  bool get hasCpu => cpuName != null || cpuCores != null;

  bool get hasGpu => gpuName != null || gpuCores != null;

  @override
  List<Object?> get props => [
    cpuName,
    cpuCores,
    cpuThreads,
    cpuClusterCores,
    cpuMaxFrequencyMhz,
    gpuName,
    gpuCores,
    memoryType,
    memoryManufacturer,
    memorySpeedMhz,
    storageModel,
    storageSolidState,
    storageNvme,
    storageInterface,
  ];
}

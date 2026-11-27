// The same file lives in ios/Runner/SystemMonitor and macos/Runner/SystemMonitor;
// keep both copies identical (GPU and power sources are macOS-only behind
// #if os(macOS), UIDevice battery is iOS-only behind #if os(iOS)).
import Foundation
import Metal

#if os(macOS)
  import IOKit
  import IOKit.ps
#endif
#if os(iOS)
  import UIKit
#endif

/// RAM and whole-device CPU (Mach host statistics), network (getifaddrs,
/// loopback excluded), storage (volume resource values), battery (UIDevice on
/// iOS, IOKit power sources plus AppleSmartBattery health and cycles on macOS)
/// and, on macOS, GPU utilization
/// (IOAccelerator). Raw counters only; Dart computes rates. Hardware facts come
/// from sysctl (cores), Metal (GPU name) and, on macOS, IOKit (GPU cores) and
/// system_profiler (RAM type, drive). Nothing leaves the device.
final class SystemMonitor: SystemMonitorHostApi {
  private let host = mach_host_self()

  #if os(macOS)
    private struct BatteryWear {
      var healthPercent: Double?
      var cycleCount: Int64?
      var designMah: Int64?
      var fullMah: Int64?
    }

    /// Health and cycles change over weeks; read the IORegistry once a minute at most.
    private var wear: BatteryWear?
    private var wearReadAt: TimeInterval = 0
    private static let wearMaxAge: TimeInterval = 60
  #endif

  func capabilities() throws -> SystemCapabilitiesMsg {
    var gpu = false
    #if os(macOS)
      gpu = gpuPercent() != nil
    #endif
    return SystemCapabilitiesMsg(
      memory: memory() != nil,
      cpu: cpuTicks() != nil,
      gpu: gpu,
      network: networkBytes() != nil,
      storage: try storage().totalBytes != nil,
      battery: try battery().levelPercent != nil
    )
  }

  func sample() throws -> SystemSampleMsg {
    let memory = memory()
    let cpu = cpuTicks()
    let network = networkBytes()
    var gpu: Double?
    #if os(macOS)
      gpu = gpuPercent()
    #endif
    return SystemSampleMsg(
      uptimeMillis: Int64(ProcessInfo.processInfo.systemUptime * 1000),
      memoryUsedBytes: memory.map { Int64(clamping: $0.used) },
      memoryTotalBytes: memory.map { Int64(clamping: $0.total) },
      cpuBusyTicks: cpu?.busy,
      cpuTotalTicks: cpu?.total,
      gpuPercent: gpu,
      networkRxBytes: network.map { Int64(clamping: $0.rx) },
      networkTxBytes: network.map { Int64(clamping: $0.tx) }
    )
  }

  /// The volume holding the app's files (the app container on iOS, the home
  /// folder on macOS). Free space is what apps can still use for important data.
  func storage() throws -> SystemStorageMsg {
    let path = NSHomeDirectory()
    let values = try? URL(fileURLWithPath: path).resourceValues(forKeys: [
      .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey,
    ])
    var total = values?.volumeTotalCapacity.map { Int64($0) }
    var free = values?.volumeAvailableCapacityForImportantUsage.flatMap { $0 > 0 ? $0 : nil }
      ?? values?.volumeAvailableCapacity.map { Int64($0) }
    if total == nil || free == nil, let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path) {
      total = total ?? (attributes[.systemSize] as? NSNumber)?.int64Value
      free = free ?? (attributes[.systemFreeSize] as? NSNumber)?.int64Value
    }
    guard let total, total > 0, let free else {
      return SystemStorageMsg()
    }
    return SystemStorageMsg(totalBytes: total, freeBytes: min(max(free, 0), total))
  }

  /// No level (desktop Mac, simulator) means no battery data; Dart hides the card.
  func battery() throws -> SystemBatteryMsg {
    #if os(iOS)
      // Pigeon calls host methods on the main thread.
      return MainActor.assumeIsolated {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let state: BatteryStateMsg =
          switch device.batteryState {
          case .charging: .charging
          case .full: .full
          case .unplugged: .discharging
          default: .unknown
          }
        guard level >= 0, state != .unknown else {
          return SystemBatteryMsg(state: .unknown)
        }
        return SystemBatteryMsg(levelPercent: Double(level) * 100, state: state)
      }
    #else
      return macBattery()
    #endif
  }

  func hardware() async throws -> SystemHardwareMsg {
    await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: Self.readHardware())
      }
    }
  }

  private static func readHardware() -> SystemHardwareMsg {
    let physical = sysctlInt("hw.physicalcpu")
    let logical = sysctlInt("hw.logicalcpu")
    // Apple silicon: perflevel0 is the performance cluster, perflevel1 efficiency.
    let levels = sysctlInt("hw.nperflevels") ?? 0
    let clusters = (0..<levels).compactMap { sysctlInt("hw.perflevel\($0).physicalcpu") }
    let metalName = MTLCreateSystemDefaultDevice()?.name
    var msg = SystemHardwareMsg(
      cpuCores: physical,
      cpuThreads: logical,
      cpuClusterCores: clusters.count > 1 && clusters.count == levels ? clusters : nil,
      gpuName: metalName
    )
    #if os(macOS)
      msg.cpuName = sysctlString("machdep.cpu.brand_string")
      if let gpu = appleGpu() {
        msg.gpuName = gpu.name ?? msg.gpuName
        msg.gpuCores = gpu.cores
      }
      applyProfiler(to: &msg)
    #else
      // iOS has no chip name; Metal's "Apple A16 GPU" names it.
      if let metalName, metalName.hasSuffix(" GPU") {
        msg.cpuName = String(metalName.dropLast(4))
      }
    #endif
    return msg
  }

  private static func sysctlInt(_ name: String) -> Int64? {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0, value > 0 else {
      return nil
    }
    return Int64(value)
  }

  private static func sysctlString(_ name: String) -> String? {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else {
      return nil
    }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else {
      return nil
    }
    let text = String(cString: buffer).trimmingCharacters(in: .whitespaces)
    return text.isEmpty ? nil : text
  }

  /// "Memory Used" as Activity Monitor counts it: app memory + wired + compressed.
  private func memory() -> (used: UInt64, total: UInt64)? {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
    let result = withUnsafeMutablePointer(to: &stats) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(host, HOST_VM_INFO64, $0, &count)
      }
    }
    var pageSize: vm_size_t = 0
    guard result == KERN_SUCCESS, host_page_size(host, &pageSize) == KERN_SUCCESS else {
      return nil
    }
    let page = UInt64(pageSize)
    let anonymous = UInt64(stats.internal_page_count)
    let purgeable = UInt64(stats.purgeable_count)
    let app = anonymous > purgeable ? anonymous - purgeable : 0
    let used = (app + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * page
    let total = ProcessInfo.processInfo.physicalMemory
    return (min(used, total), total)
  }

  /// Cumulative ticks of all cores. They are 32-bit and can wrap; Dart skips
  /// a sample whose delta goes negative.
  private func cpuTicks() -> (busy: Int64, total: Int64)? {
    var info = host_cpu_load_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
      }
    }
    guard result == KERN_SUCCESS else {
      return nil
    }
    // Order: CPU_STATE_USER, CPU_STATE_SYSTEM, CPU_STATE_IDLE, CPU_STATE_NICE.
    let (user, system, idle, nice) = info.cpu_ticks
    let busy = Int64(user) + Int64(system) + Int64(nice)
    return (busy, busy + Int64(idle))
  }

  /// Bytes of every interface that is up, except loopback. if_data counters
  /// are 32-bit; a wrap shows up as a negative delta, which Dart skips.
  private func networkBytes() -> (rx: UInt64, tx: UInt64)? {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else {
      return nil
    }
    defer { freeifaddrs(head) }
    var rx: UInt64 = 0
    var tx: UInt64 = 0
    for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
      let entry = pointer.pointee
      let flags = Int32(entry.ifa_flags)
      guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK),
        flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0, let data = entry.ifa_data
      else {
        continue
      }
      let counters = data.assumingMemoryBound(to: if_data.self).pointee
      rx += UInt64(counters.ifi_ibytes)
      tx += UInt64(counters.ifi_obytes)
    }
    return (rx, tx)
  }

  #if os(macOS)
    /// The internal battery from IOKit power sources. Time remaining is only
    /// set once macOS has estimated it (it reports -1 while calculating).
    private func macBattery() -> SystemBatteryMsg {
      let none = SystemBatteryMsg(state: .unknown)
      guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
        let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
      else {
        return none
      }
      for source in sources {
        guard
          let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
            as? [String: Any],
          description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
          description[kIOPSIsPresentKey] as? Bool ?? true,
          let current = (description[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue,
          let maximum = (description[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue, maximum > 0
        else {
          continue
        }
        let charging = description[kIOPSIsChargingKey] as? Bool ?? false
        let charged = description[kIOPSIsChargedKey] as? Bool ?? false
        let onPower = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        let state: BatteryStateMsg =
          charged ? .full : charging ? .charging : onPower ? .notCharging : .discharging
        var minutes: Int64?
        if state == .charging || state == .discharging,
          let value = (description[charging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey] as? NSNumber)?
            .int64Value, value > 0
        {
          minutes = value
        }
        let wear = batteryWear()
        return SystemBatteryMsg(
          levelPercent: min(max(current * 100 / maximum, 0), 100),
          state: state,
          minutesRemaining: minutes,
          healthPercent: wear.healthPercent,
          cycleCount: wear.cycleCount,
          designCapacityMah: wear.designMah,
          fullChargeCapacityMah: wear.fullMah,
          remainingCapacityMah: remainingMah()
        )
      }
      return none
    }

    /// Health (full-charge capacity ÷ design capacity) and cycle count from the
    /// AppleSmartBattery IORegistry entry, cached for `wearMaxAge`.
    private func batteryWear() -> BatteryWear {
      let now = ProcessInfo.processInfo.systemUptime
      if let wear, now - wearReadAt < Self.wearMaxAge {
        return wear
      }
      let fresh = readBatteryWear()
      wear = fresh
      wearReadAt = now
      return fresh
    }

    private func readBatteryWear() -> BatteryWear {
      guard let battery = SmartBattery() else {
        return BatteryWear()
      }
      // On Apple silicon "MaxCapacity" is a percentage, so use the raw mAh values.
      let design = battery.mah("DesignCapacity")
      let full = battery.mah("AppleRawMaxCapacity") ?? battery.mah("NominalChargeCapacity")
      var health: Double?
      var validFull: Int64?
      if let design, let full {
        let ratio = Double(full) / Double(design) * 100
        // Far outside 0–150% means the keys don't hold what we expect.
        if ratio.isFinite, ratio > 0, ratio <= 150 {
          health = min(ratio, 100)
          validFull = full
        }
      }
      let cycles = battery.number("CycleCount")?.int64Value
      return BatteryWear(
        healthPercent: health,
        cycleCount: cycles.flatMap { $0 >= 0 && $0 < 100_000 ? $0 : nil },
        designMah: design,
        fullMah: validFull
      )
    }

    /// Charge left in mAh, read each time (it changes by the minute).
    private func remainingMah() -> Int64? {
      SmartBattery()?.mah("AppleRawCurrentCapacity")
    }

    /// The AppleSmartBattery IORegistry entry. Newer macOS keeps the raw mAh
    /// values only inside "BatteryData", so each key falls back to it.
    private final class SmartBattery {
      private let service: io_registry_entry_t
      private let data: [String: Any]?

      init?() {
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else {
          return nil
        }
        data =
          IORegistryEntryCreateCFProperty(service, "BatteryData" as CFString, kCFAllocatorDefault, 0)?
          .takeRetainedValue() as? [String: Any]
      }

      deinit { IOObjectRelease(service) }

      func number(_ key: String) -> NSNumber? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
          .takeRetainedValue() as? NSNumber ?? data?[key] as? NSNumber
      }

      /// A capacity in mAh; zero, negative or absurd values mean the key isn't what we expect.
      func mah(_ key: String) -> Int64? {
        number(key).map(\.int64Value).flatMap { $0 > 0 && $0 < 100_000 ? $0 : nil }
      }
    }

    /// The Apple silicon GPU's name and core count from its IOAccelerator entry.
    private static func appleGpu() -> (name: String?, cores: Int64?)? {
      let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AGXAccelerator"))
      guard service != 0 else {
        return nil
      }
      defer { IOObjectRelease(service) }
      func property(_ key: String) -> Any? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
      }
      let cores = (property("gpu-core-count") as? NSNumber)?.int64Value
      return (property("model") as? String, cores.flatMap { $0 > 0 ? $0 : nil })
    }

    /// RAM type and the app's drive from `system_profiler -json` (about 0.2 s).
    private static func applyProfiler(to msg: inout SystemHardwareMsg) {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
      process.arguments = ["-json", "-detailLevel", "mini", "SPMemoryDataType", "SPStorageDataType", "SPNVMeDataType"]
      let pipe = Pipe()
      process.standardOutput = pipe
      process.standardError = FileHandle.nullDevice
      guard (try? process.run()) != nil else {
        return
      }
      let output = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0,
        let root = try? JSONSerialization.jsonObject(with: output) as? [String: Any]
      else {
        return
      }
      func text(_ value: Any?) -> String? {
        (value as? String).flatMap { $0.isEmpty || $0.lowercased() == "empty" ? nil : $0 }
      }

      // Apple silicon lists one entry with the type on top; Intel lists DIMM slots under "_items".
      if let memory = (root["SPMemoryDataType"] as? [[String: Any]])?.first {
        let slots = (memory["_items"] as? [[String: Any]])?.flatMap { $0["_items"] as? [[String: Any]] ?? [$0] } ?? []
        let filled = slots.first { text($0["dimm_type"]) != nil }
        msg.memoryType = text(memory["dimm_type"]) ?? text(filled?["dimm_type"])
        msg.memoryManufacturer = text(memory["dimm_manufacturer"]) ?? text(filled?["dimm_manufacturer"])
        if let speed = text(filled?["dimm_speed"]), let mhz = Int64(speed.split(separator: " ").first ?? "") {
          msg.memorySpeedMhz = mhz
        }
      }

      // The volume holding the home folder. /Users is firmlinked to the Data
      // volume on modern macOS, so a match on "/" means the Data volume.
      let volumes = root["SPStorageDataType"] as? [[String: Any]] ?? []
      func mounted(at path: String) -> [String: Any]? {
        volumes.first { text($0["mount_point"]) == path }
      }
      let home = NSHomeDirectory()
      var volume = volumes
        .filter { text($0["mount_point"]).map { home.hasPrefix($0) } ?? false }
        .max { (text($0["mount_point"])?.count ?? 0) < (text($1["mount_point"])?.count ?? 0) }
      if volume.map({ text($0["mount_point"]) == "/" }) ?? true {
        volume = mounted(at: "/System/Volumes/Data") ?? volume
      }
      if let drive = volume?["physical_drive"] as? [String: Any] {
        let model = text(drive["device_name"])
        msg.storageModel = model
        msg.storageInterface = text(drive["protocol"])
        if let medium = text(drive["medium_type"])?.lowercased() {
          msg.storageSolidState = medium == "ssd" ? true : medium == "rotational" ? false : nil
        }
        let nvmeModels = (root["SPNVMeDataType"] as? [[String: Any]] ?? [])
          .flatMap { $0["_items"] as? [[String: Any]] ?? [] }
          .compactMap { text($0["device_model"]) ?? text($0["_name"]) }
        if let model {
          msg.storageNvme = nvmeModels.contains(model)
        }
      }
    }

    /// Highest "Device Utilization %" across GPUs, or nil when no GPU driver reports it.
    private func gpuPercent() -> Double? {
      var iterator: io_iterator_t = 0
      guard
        IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator)
          == KERN_SUCCESS
      else {
        return nil
      }
      defer { IOObjectRelease(iterator) }
      var highest: Double?
      var service = IOIteratorNext(iterator)
      while service != 0 {
        if let property = IORegistryEntryCreateCFProperty(
          service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0),
          let stats = property.takeRetainedValue() as? [String: Any],
          let value = (stats["Device Utilization %"] as? NSNumber)?.doubleValue
        {
          highest = max(highest ?? 0, min(max(value, 0), 100))
        }
        IOObjectRelease(service)
        service = IOIteratorNext(iterator)
      }
      return highest
    }
  #endif
}

// The same file lives in ios/Runner/SystemMonitor and macos/Runner/SystemMonitor;
// keep both copies identical (GPU and power sources are macOS-only behind
// #if os(macOS), UIDevice battery is iOS-only behind #if os(iOS)).
import Foundation

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
/// (IOAccelerator). Raw counters only; Dart computes rates. Nothing leaves the device.
final class SystemMonitor: SystemMonitorHostApi {
  private let host = mach_host_self()

  #if os(macOS)
    /// Health and cycles change over weeks; read the IORegistry once a minute at most.
    private var wear: (healthPercent: Double?, cycleCount: Int64?)?
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
          cycleCount: wear.cycleCount
        )
      }
      return none
    }

    /// Health (full-charge capacity ÷ design capacity) and cycle count from the
    /// AppleSmartBattery IORegistry entry, cached for `wearMaxAge`.
    private func batteryWear() -> (healthPercent: Double?, cycleCount: Int64?) {
      let now = ProcessInfo.processInfo.systemUptime
      if let wear, now - wearReadAt < Self.wearMaxAge {
        return wear
      }
      let fresh = readBatteryWear()
      wear = fresh
      wearReadAt = now
      return fresh
    }

    private func readBatteryWear() -> (healthPercent: Double?, cycleCount: Int64?) {
      let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
      guard service != 0 else {
        return (nil, nil)
      }
      defer { IOObjectRelease(service) }
      func number(_ key: String, in entry: io_registry_entry_t) -> NSNumber? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?
          .takeRetainedValue() as? NSNumber
      }
      // Newer macOS keeps the raw mAh values only inside "BatteryData".
      let data =
        IORegistryEntryCreateCFProperty(service, "BatteryData" as CFString, kCFAllocatorDefault, 0)?
        .takeRetainedValue() as? [String: Any]
      func capacity(_ key: String) -> Double? {
        let value = number(key, in: service)?.doubleValue ?? (data?[key] as? NSNumber)?.doubleValue
        return value.flatMap { $0 > 0 ? $0 : nil }
      }
      // On Apple silicon "MaxCapacity" is a percentage, so use the raw mAh values.
      var health: Double?
      if let design = capacity("DesignCapacity"),
        let full = capacity("AppleRawMaxCapacity") ?? capacity("NominalChargeCapacity")
      {
        let ratio = full / design * 100
        // Far outside 0–150% means the keys don't hold what we expect.
        if ratio.isFinite, ratio > 0, ratio <= 150 {
          health = min(ratio, 100)
        }
      }
      let cycles = number("CycleCount", in: service)?.int64Value ?? (data?["CycleCount"] as? NSNumber)?.int64Value
      return (health, cycles.flatMap { $0 >= 0 && $0 < 100_000 ? $0 : nil })
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

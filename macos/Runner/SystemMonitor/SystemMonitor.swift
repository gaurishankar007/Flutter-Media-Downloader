// The same file lives in ios/Runner/SystemMonitor and macos/Runner/SystemMonitor;
// keep both copies identical (GPU is macOS-only behind #if os(macOS)).
import Foundation

#if os(macOS)
  import IOKit
#endif

/// RAM and whole-device CPU (Mach host statistics), network (getifaddrs,
/// loopback excluded) and, on macOS, GPU utilization (IOAccelerator).
/// Raw counters only; Dart computes rates. Nothing leaves the device.
final class SystemMonitor: SystemMonitorHostApi {
  private let host = mach_host_self()

  func capabilities() throws -> SystemCapabilitiesMsg {
    var gpu = false
    #if os(macOS)
      gpu = gpuPercent() != nil
    #endif
    return SystemCapabilitiesMsg(
      memory: memory() != nil,
      cpu: cpuTicks() != nil,
      gpu: gpu,
      network: networkBytes() != nil
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

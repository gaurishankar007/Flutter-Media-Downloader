# System

> Status: built, not yet tested on every device. Feature folder: `lib/ui/features/system/`.

The **System** tab (4th of the 5 tabs: Download, Library, Convert, System, Settings; route `system`, child of the home shell) shows live device stats: network, battery, RAM, CPU, GPU and storage, one card each. Network, RAM, CPU and GPU show the last minute as a sparkline; battery and storage show a bar and detail rows. Cards also list fixed **hardware facts** (chip, cores, GPU cores, RAM type, drive, battery capacity), and RAM and Storage have a user-started **speed test**. Only what the running platform can report is shown. Nothing leaves the device.

## What Each Platform Reports

| Platform | RAM | CPU | GPU | Network | Storage | Battery | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android | ✅ | — (info card: chip, cores, clusters, max clock) | — | ✅ (when `TrafficStats` is supported) | ✅ | ✅ level, state, temperature, health, cycles (Android 14+, when the device reports them), charge left in mAh (when the fuel gauge reports it) | `ActivityManager.MemoryInfo` (total − available), `TrafficStats.getTotalRx/TxBytes`, `StatFs(filesDir)`, the sticky `ACTION_BATTERY_CHANGED` intent (no permission; `EXTRA_CYCLE_COUNT` on API 34+). `BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER` (µAh, or mAh on some gauges). Android hides `/proc/stat` and GPU load from apps. |
| iOS | ✅ | ✅ | — (info card: GPU name) | ✅ | ✅ | ✅ level and state only | Mach `host_statistics64(HOST_VM_INFO64)` + `physicalMemory`, `host_statistics(HOST_CPU_LOAD_INFO)`, `getifaddrs` (interfaces that are up, loopback excluded), volume resource values of `NSHomeDirectory()`, `UIDevice` battery monitoring. No public API for battery health or cycles. |
| macOS | ✅ | ✅ | ✅ (when a GPU driver reports it) | ✅ | ✅ | ✅ (laptops) level, state, time remaining, health %, cycles, design / full-charge / remaining mAh | Same as iOS, plus IOKit `IOAccelerator` → `PerformanceStatistics` "Device Utilization %" (highest across GPUs), IOKit power sources (`IOPSCopyPowerSourcesInfo`, internal battery) and the `AppleSmartBattery` IORegistry entry |

- RAM "used" on iOS/macOS is counted like Activity Monitor: app memory + wired + compressed.
- CPU and network are whole-device, not just this app.
- **Storage** is the volume holding the app's files: used / free / total, and **Media Tool files** (size and share of the volume). iOS/macOS free space is `volumeAvailableCapacityForImportantUsage` (falling back to `volumeAvailableCapacity`, then `attributesOfFileSystem`). The app's size is the whole `AppDirectories.base` folder (downloads, thumbnails, cookies, the database), walked in Dart by `AppFilesLocalService` inside `Isolate.run` so thousands of files never block the UI; the cache `work/` folder isn't counted. Sizes use 1024-based units (`FormatUtils.bytes`, up to TB).
- **Battery** is hidden on devices without battery data (desktop Macs, simulators). macOS health is full-charge ÷ design capacity (`AppleRawMaxCapacity`, else `NominalChargeCapacity`, over `DesignCapacity`, read at the top level or inside `BatteryData`; capped at 100 %), cached for 60 s because it changes over weeks. Time remaining shows only once macOS has an estimate ("Time left" on battery, "Until full" while charging). At or below 20 % on battery the bar turns `warning` (amber).
- **Battery capacity** (macOS): design (`DesignCapacity`) and full charge (`AppleRawMaxCapacity`, else `NominalChargeCapacity`) come from the same 60 s cache as health; charge left (`AppleRawCurrentCapacity`) is read on every poll. Android reports only charge left (the charge counter, documented as µAh; some gauges such as Xiaomi's report mAh, detected when the µAh reading would imply a whole battery under 500 mAh at the current level; values outside 1–30,000 mAh are dropped). There's no public design-capacity API on Android or iOS.
- Each native side decides its capabilities at runtime (e.g. macOS reports GPU only if a reading succeeds, battery only if a level is read). A platform that reports nothing shows an empty state; since every platform reports storage, that practically never happens.

## Hardware Facts

Read once per app session by `hardware()` (async, off the main thread) and cached in the repository. Every field is null where the platform doesn't tell apps.

| Fact | Android | iOS | macOS |
| --- | --- | --- | --- |
| Processor name | `Build.SOC_MANUFACTURER` + `SOC_MODEL` (Android 12+, e.g. "QTI SM8550"), else `Build.HARDWARE` | Metal GPU name without " GPU" ("Apple A16") | `machdep.cpu.brand_string` ("Apple M4 Pro") |
| Cores / threads | `/sys/devices/system/cpu/possible` (threads = cores; phone cores run one thread) | `hw.physicalcpu` / `hw.logicalcpu` | same (threads differ on Intel with hyper-threading) |
| Core layout | cores grouped by `cpufreq/cpuinfo_max_freq`, fastest first | `hw.perflevelN.physicalcpu` | same |
| Max clock | fastest `cpuinfo_max_freq` | — | — |
| GPU | — | Metal device name | IOKit `AGXAccelerator` `model` + `gpu-core-count` (Apple silicon), else Metal name |
| RAM type / manufacturer / clock | — | — | `system_profiler -json SPMemoryDataType` (Apple silicon: one entry; Intel: DIMM slots with `dimm_speed`) |
| Drive model / type / interface | — | — | `system_profiler -json SPStorageDataType SPNVMeDataType`: the volume holding the home folder (the Data volume when that matches `/`), its `physical_drive` (`device_name`, `medium_type`, `protocol`); NVMe when the model is listed under SPNVMeDataType |

`system_profiler` runs once with `-detailLevel mini` (about 0.2 s). The macOS app isn't sandboxed, so it can start it; iOS can't, and neither platform exposes the rest of this to apps. UFS version, RAM type and GPU cores aren't readable on phones.

The **layout** row reads "8 performance + 4 efficiency" for two clusters, "1 prime + 3 performance + 4 efficiency" for three, and joins other counts with " + ".

## Speed Tests

User-started, one at a time, from a **Test speed** button on the RAM and Storage cards. `SpeedTestService` (`lib/data/services/platform/speed_test/`) calls libc through `dart:ffi` (`DynamicLibrary.open('libc.so')` on Android, `DynamicLibrary.process()` on iOS/macOS), so the loops run at native speed even in debug builds, each inside `Isolate.run`.

| Test | Size | What it measures |
| --- | --- | --- |
| RAM | 256 MB (macOS), 128 MB (phones), page-aligned (`posix_memalign`) | Pages are touched first. **Write** = `memset`, **Read** = `memchr` for a byte that isn't there (scans the whole block), **Copy** = `memcpy` into a second block. Each repeats for at least 250 ms; bytes per second over all passes. |
| Storage | 1 GB (macOS), 512 MB (phones), in 4 MB chunks of random data | Writes `work/speed_test.tmp`, flushes it (`F_FULLFSYNC` on Darwin, else `fsync`), then reads it back. Cache is bypassed: `F_NOCACHE` on iOS/macOS, `posix_fadvise(POSIX_FADV_DONTNEED)` after the flush and before the read on Android. The file is always deleted. |

- The storage test needs twice its file size free, else it fails with `CommonMessages.noSpace`.
- Results are measured throughput right now, not the rated speed of the part. Sizes use 1024-based units (`FormatUtils.speed`).
- The last result per test is kept in the repository for the app session, so leaving and returning to the tab keeps it. A test still running when the tab is left finishes and is stored, but the button state resets.
- Flag values differ between Linux and Darwin (`O_CREAT`, `O_TRUNC`); `open` and `fcntl` are called as variadic (`VarArgs`).

## Bridge

Pigeon input: `lib/config/pigeon/system_monitor_api.dart` (regenerate with `dart run pigeon --input lib/config/pigeon/system_monitor_api.dart`).

```dart
@HostApi()
abstract class SystemMonitorHostApi {
  SystemCapabilitiesMsg capabilities(); // memory, cpu, gpu, network, storage, battery: bool
  SystemSampleMsg sample();             // raw counters, null where unsupported
  SystemStorageMsg storage();           // totalBytes, freeBytes (null when unreadable)
  SystemBatteryMsg battery();           // levelPercent (null = no battery), state, platform extras
  @async SystemHardwareMsg hardware();  // fixed hardware facts, null where unknown
}
```

`SystemSampleMsg` carries **raw counters only**: `uptimeMillis` (monotonic), memory used/total, cumulative CPU busy/total ticks, instant `gpuPercent`, cumulative network rx/tx bytes. Native code keeps no state (except the macOS battery-health cache).

`SystemBatteryMsg`: `levelPercent`, `state` (`BatteryStateMsg`: charging, full, discharging, notCharging, unknown), and extras that are null elsewhere: `temperatureCelsius` and `health` (`BatteryHealthMsg`, Android), `minutesRemaining` and `healthPercent` (macOS), `cycleCount` (macOS; Android 14+), `designCapacityMah` and `fullChargeCapacityMah` (macOS), `remainingCapacityMah` (macOS, Android).

`SystemHardwareMsg`: `cpuName`, `cpuCores`, `cpuThreads`, `cpuClusterCores` (fastest first), `cpuMaxFrequencyMhz`, `gpuName`, `gpuCores`, `memoryType`, `memoryManufacturer`, `memorySpeedMhz`, `storageModel`, `storageSolidState`, `storageNvme`, `storageInterface`. Swift runs it on a global queue; Kotlin as a `suspend` function on `Dispatchers.IO`.

| Side | File |
| --- | --- |
| Dart client | `lib/core/clients/platform/system_monitor_api.g.dart` |
| Android | `android/app/src/main/kotlin/.../system/SystemMonitor.kt` (+ `SystemMonitorApi.g.kt`) |
| iOS | `ios/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |
| macOS | `macos/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |

The iOS and macOS `SystemMonitor.swift` files are identical copies (GPU and power sources behind `#if os(macOS)`, `UIDevice` battery behind `#if os(iOS)`); keep them in sync by hand. Pigeon writes the Swift output to both folders, with its own error class name (`SystemMonitorPigeonError`) so it never clashes with other Pigeon files.

## Data Layer

- `SystemMonitorService` (`lib/data/services/platform/system_monitor/`): thin Pigeon wrapper; throws.
- `SpeedTestService` (`lib/data/services/platform/speed_test/`): the FFI RAM and storage tests (see Speed Tests); returns raw bytes per second; throws.
- `AppFilesLocalService` (`lib/data/services/local/app_files_local_service.dart`): `sizeInBytes()` of `AppDirectories.base`, walked off the UI isolate; unreadable folders and files deleted mid-walk are skipped. Throws.
- `SystemMonitorRepositoryImpl`: wraps calls in `ErrorHandler` (`systemMonitor.profile`, `systemMonitor.hardware`, `systemMonitor.sample`, `systemMonitor.storage`, `systemMonitor.battery`, `systemMonitor.speedTest.<memory|storage>`), caches the `SystemProfile` (`knownProfile`), keeps the previous raw sample, the last app-folder size and the last speed test results (`lastSpeedTest`). A failed hardware read is logged and the profile is built without it, so the live cards still show. `storage(measureAppFiles:)` walks the app folder again only when asked (or never measured) and reuses the last size otherwise.
- Domain models: `SystemProfile` (`metrics` in card order, `liveMetrics`, `hardware`), `DeviceHardware`, `DeviceStorage` (total / free / app bytes, `usedFraction`, `appFraction`), `BatteryStatus` with `BatteryChargeState` and `BatteryHealth` (plus the mAh fields), `SpeedTest` (`memory`, `storage`) and `SpeedTestResult` (read / write / copy bytes per second).
- `SystemSampleMapper`: capabilities + hardware → `SystemProfile`. Cards are in `SystemMetric` declaration order (**network, battery, memory, cpu, gpu, storage**): every live metric, plus CPU or GPU as an **info-only** card when the platform has no live load but hardware facts exist (CPU on Android, GPU on iOS). Hardware message → `DeviceHardware` (blank strings and non-positive numbers dropped); storage / battery messages → `DeviceStorage?` / `BatteryStatus?` (null without a total or a level; health % and cycles dropped when out of range); two raw samples → `SystemSample` with CPU % (busy delta / total delta) and download/upload bytes per second. Readings more than 5 s apart (the monitor was paused) or with a negative delta (32-bit counter wrapped, interface gone) give no rate for that second.

## Provider

| Provider | Owns | Notes |
| --- | --- | --- |
| `systemMonitorProvider` (`SystemMonitorNotifier`, `.autoDispose`) | `metrics`, `liveMetrics`, `metricsKnown`, `hardware`, `latest` sample, `history` (≤ 60 samples, oldest first), `storage`, `battery`, `speedResults`, `runningTest` | Polls `sample()` (RAM, CPU, GPU, network) every **1 s**; storage and battery every **5 s** (`slowEvery`); the app folder size on open and every **30 s** (`appFilesEvery`). Stops after 3 failed `sample()` readings in a row; a failed storage/battery reading keeps the last values. Polling covers `liveMetrics` only. Failures stay in the error log only; the monitor never toasts. `runSpeedTest(test)` (flow `systemMonitor.speedTest`) is ignored while a test runs; its failure sets a `StateMessage` that the screen toasts with `ToastUtil`. |

**Polling only while visible.** Tabs stay mounted in `AutoTabsRouter`, so `SystemScreen` watches the provider only when the System tab is the active tab, no route covers it, and the app is visible (`resumed` or `inactive`, `isAppVisible`). Otherwise it doesn't watch, the autoDispose notifier is disposed and its timer stops. The metric list is cached in the repository, so coming back doesn't flash the layout.

## Screen

```text
system/
  models/ monitor_visibility.dart, system_metric_display.dart   # label, body, icon, value formatting
  providers/system_monitor/ system_monitor_notifier.dart, system_monitor_state.dart
  views/system/
    system_screen.dart
    widgets/ metric_cards_grid.dart, system_metric_card.dart, gauge_metric_card.dart, bar_metric_card.dart,
             info_metric_card.dart, network_metric_card.dart, speed_test_section.dart, metric_value_row.dart,
             metric_card_header.dart, sparkline.dart
```

- `MetricCardsGrid`: one column on phones, two (equal height per row) once two 320 px cards fit.
- **RAM / CPU / GPU** (`GaugeMetricCard`): percent, `GradientProgressBar`, RAM detail ("X of Y"), a `Sparkline` fixed to 0–100%, then hardware rows and an optional `footer`. RAM: Type, Manufacturer, Clock, then the speed test. CPU: Processor, Cores, Threads, Layout, Max clock. GPU: Graphics, GPU cores.
- **Info-only CPU / GPU** (`InfoMetricCard`): header (`cpuInfoBody` / `gpuInfoBody`, saying the system keeps the load private) and the same hardware rows, no value, bar or sparkline.
- **Speed test** (`SpeedTestSection`): result rows (Read / Write speed, plus Copy for RAM) or, before a run, a muted note on what the test does; a full-width `TonalButton` "Test speed" / "Testing…" / "Test again", disabled while any test runs.
- **Battery / Storage** (`BarMetricCard`): percent, `GradientProgressBar` (optional solid `barColor`, e.g. `warning` for a low battery) and label/value rows (`MetricValueRow`), no sparkline. Battery: Status, Time left / Until full, Temperature, Health ("Good · 92%": condition, capacity or both), Cycles, Design capacity, Full charge, Charge left ("6,249 mAh"), each only when known; the icon switches to charging while charging. Storage: Used, Free, Total, Media Tool files ("1.2 GB · 0.5%", "<1%" below one percent), Drive, Type ("NVMe SSD · Apple Fabric"), then the speed test.
- `MetricValueRow`: the value takes the remaining width, right-aligned, and wraps, so long chip names or core layouts never overflow.
- **Network** (`NetworkMetricCard`): download and upload speed rows (`MetricValueRow` with an icon) and a two-line sparkline (download in the Aurora gradient, upload thinner in the secondary colour), scaled to the busiest second shown. Speeds below 512 B/s read "0 KB/s" (`SystemMessages.idleSpeed`).
- `Sparkline`: a `CustomPainter` over 60 slots (one per second), newest at the right edge, caption "Last 60 seconds".
- States: shimmer cards until the capabilities are known; "—" for values until there are two readings (storage and battery: until their first reading); an empty state when the device reports none of the stats (practically never, since storage is always available).

All text is in `SystemMessages` (`lib/core/messages/app_messages.dart`).

# System

> Status: built, not yet tested on every device. Feature folder: `lib/ui/features/system/`.

The **System** tab (4th of the 5 tabs: Download, Library, Convert, System, Settings; route `system`, child of the home shell) shows live device stats: network, battery, RAM, CPU, GPU and storage, one card each. Network, RAM, CPU and GPU show the last minute as a sparkline; battery and storage show a bar and detail rows. Only the metrics the running platform can report are shown. Nothing leaves the device.

## What Each Platform Reports

| Platform | RAM | CPU | GPU | Network | Storage | Battery | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android | ✅ | — | — | ✅ (when `TrafficStats` is supported) | ✅ | ✅ level, state, temperature, health, cycles (Android 14+, when the device reports them) | `ActivityManager.MemoryInfo` (total − available), `TrafficStats.getTotalRx/TxBytes`, `StatFs(filesDir)`, the sticky `ACTION_BATTERY_CHANGED` intent (no permission; `EXTRA_CYCLE_COUNT` on API 34+). Android hides `/proc/stat` and GPU load from apps. |
| iOS | ✅ | ✅ | — | ✅ | ✅ | ✅ level and state only | Mach `host_statistics64(HOST_VM_INFO64)` + `physicalMemory`, `host_statistics(HOST_CPU_LOAD_INFO)`, `getifaddrs` (interfaces that are up, loopback excluded), volume resource values of `NSHomeDirectory()`, `UIDevice` battery monitoring. No public API for battery health or cycles. |
| macOS | ✅ | ✅ | ✅ (when a GPU driver reports it) | ✅ | ✅ | ✅ (laptops) level, state, time remaining, health %, cycles | Same as iOS, plus IOKit `IOAccelerator` → `PerformanceStatistics` "Device Utilization %" (highest across GPUs), IOKit power sources (`IOPSCopyPowerSourcesInfo`, internal battery) and the `AppleSmartBattery` IORegistry entry |

- RAM "used" on iOS/macOS is counted like Activity Monitor: app memory + wired + compressed.
- CPU and network are whole-device, not just this app.
- **Storage** is the volume holding the app's files: used / free / total, and **Media Tool files** (size and share of the volume). iOS/macOS free space is `volumeAvailableCapacityForImportantUsage` (falling back to `volumeAvailableCapacity`, then `attributesOfFileSystem`). The app's size is the whole `AppDirectories.base` folder (downloads, thumbnails, cookies, the database), walked in Dart by `AppFilesLocalService` inside `Isolate.run` so thousands of files never block the UI; the cache `work/` folder isn't counted. Sizes use 1024-based units (`FormatUtils.bytes`, up to TB).
- **Battery** is hidden on devices without battery data (desktop Macs, simulators). macOS health is full-charge ÷ design capacity (`AppleRawMaxCapacity`, else `NominalChargeCapacity`, over `DesignCapacity`, read at the top level or inside `BatteryData`; capped at 100 %), cached for 60 s because it changes over weeks. Time remaining shows only once macOS has an estimate ("Time left" on battery, "Until full" while charging). At or below 20 % on battery the bar turns `warning` (amber).
- Each native side decides its capabilities at runtime (e.g. macOS reports GPU only if a reading succeeds, battery only if a level is read). A platform that reports nothing shows an empty state; since every platform reports storage, that practically never happens.

## Bridge

Pigeon input: `lib/config/pigeon/system_monitor_api.dart` (regenerate with `dart run pigeon --input lib/config/pigeon/system_monitor_api.dart`).

```dart
@HostApi()
abstract class SystemMonitorHostApi {
  SystemCapabilitiesMsg capabilities(); // memory, cpu, gpu, network, storage, battery: bool
  SystemSampleMsg sample();             // raw counters, null where unsupported
  SystemStorageMsg storage();           // totalBytes, freeBytes (null when unreadable)
  SystemBatteryMsg battery();           // levelPercent (null = no battery), state, platform extras
}
```

`SystemSampleMsg` carries **raw counters only**: `uptimeMillis` (monotonic), memory used/total, cumulative CPU busy/total ticks, instant `gpuPercent`, cumulative network rx/tx bytes. Native code keeps no state (except the macOS battery-health cache).

`SystemBatteryMsg`: `levelPercent`, `state` (`BatteryStateMsg`: charging, full, discharging, notCharging, unknown), and extras that are null elsewhere: `temperatureCelsius` and `health` (`BatteryHealthMsg`, Android), `minutesRemaining` and `healthPercent` (macOS), `cycleCount` (macOS; Android 14+).

| Side | File |
| --- | --- |
| Dart client | `lib/core/clients/platform/system_monitor_api.g.dart` |
| Android | `android/app/src/main/kotlin/.../system/SystemMonitor.kt` (+ `SystemMonitorApi.g.kt`) |
| iOS | `ios/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |
| macOS | `macos/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |

The iOS and macOS `SystemMonitor.swift` files are identical copies (GPU and power sources behind `#if os(macOS)`, `UIDevice` battery behind `#if os(iOS)`); keep them in sync by hand. Pigeon writes the Swift output to both folders, with its own error class name (`SystemMonitorPigeonError`) so it never clashes with other Pigeon files.

## Data Layer

- `SystemMonitorService` (`lib/data/services/platform/system_monitor/`): thin Pigeon wrapper; throws.
- `AppFilesLocalService` (`lib/data/services/local/app_files_local_service.dart`): `sizeInBytes()` of `AppDirectories.base`, walked off the UI isolate; unreadable folders and files deleted mid-walk are skipped. Throws.
- `SystemMonitorRepositoryImpl`: wraps calls in `ErrorHandler` (`systemMonitor.metrics`, `systemMonitor.sample`, `systemMonitor.storage`, `systemMonitor.battery`), caches the metric list (`knownMetrics`), keeps the previous raw sample and the last app-folder size. `storage(measureAppFiles:)` walks the app folder again only when asked (or never measured) and reuses the last size otherwise.
- Domain models: `DeviceStorage` (total / free / app bytes, `usedFraction`, `appFraction`), `BatteryStatus` with `BatteryChargeState` and `BatteryHealth`.
- `SystemSampleMapper`: capabilities → `List<SystemMetric>` in `SystemMetric` declaration order, which is the card order (**network, battery, memory, cpu, gpu, storage**); storage / battery messages → `DeviceStorage?` / `BatteryStatus?` (null without a total or a level; health % and cycles dropped when out of range); two raw samples → `SystemSample` with CPU % (busy delta / total delta) and download/upload bytes per second. Readings more than 5 s apart (the monitor was paused) or with a negative delta (32-bit counter wrapped, interface gone) give no rate for that second.

## Provider

| Provider | Owns | Notes |
| --- | --- | --- |
| `systemMonitorProvider` (`SystemMonitorNotifier`, `.autoDispose`) | `metrics`, `metricsKnown`, `latest` sample, `history` (≤ 60 samples, oldest first), `storage`, `battery` | Polls `sample()` (RAM, CPU, GPU, network) every **1 s**; storage and battery every **5 s** (`slowEvery`); the app folder size on open and every **30 s** (`appFilesEvery`). Stops after 3 failed `sample()` readings in a row; a failed storage/battery reading keeps the last values. Failures stay in the error log only; the monitor never toasts. |

**Polling only while visible.** Tabs stay mounted in `AutoTabsRouter`, so `SystemScreen` watches the provider only when the System tab is the active tab, no route covers it, and the app is visible (`resumed` or `inactive`, `isAppVisible`). Otherwise it doesn't watch, the autoDispose notifier is disposed and its timer stops. The metric list is cached in the repository, so coming back doesn't flash the layout.

## Screen

```text
system/
  models/ monitor_visibility.dart, system_metric_display.dart   # label, body, icon, value formatting
  providers/system_monitor/ system_monitor_notifier.dart, system_monitor_state.dart
  views/system/
    system_screen.dart
    widgets/ metric_cards_grid.dart, system_metric_card.dart, gauge_metric_card.dart, bar_metric_card.dart,
             network_metric_card.dart, metric_value_row.dart, metric_card_header.dart, sparkline.dart
```

- `MetricCardsGrid`: one column on phones, two (equal height per row) once two 320 px cards fit.
- **RAM / CPU / GPU** (`GaugeMetricCard`): percent, `GradientProgressBar`, RAM detail ("X of Y"), and a `Sparkline` fixed to 0–100%.
- **Battery / Storage** (`BarMetricCard`): percent, `GradientProgressBar` (optional solid `barColor`, e.g. `warning` for a low battery) and label/value rows (`MetricValueRow`), no sparkline. Battery: Status, Time left / Until full, Temperature, Health ("Good · 92%": condition, capacity or both), Cycles, each only when known; the icon switches to charging while charging. Storage: Used, Free, Total, Media Tool files ("1.2 GB · 0.5%", "<1%" below one percent).
- **Network** (`NetworkMetricCard`): download and upload speed rows (`MetricValueRow` with an icon) and a two-line sparkline (download in the Aurora gradient, upload thinner in the secondary colour), scaled to the busiest second shown. Speeds below 512 B/s read "0 KB/s" (`SystemMessages.idleSpeed`).
- `Sparkline`: a `CustomPainter` over 60 slots (one per second), newest at the right edge, caption "Last 60 seconds".
- States: shimmer cards until the capabilities are known; "—" for values until there are two readings (storage and battery: until their first reading); an empty state when the device reports none of the stats (practically never, since storage is always available).

All text is in `SystemMessages` (`lib/core/messages/app_messages.dart`).

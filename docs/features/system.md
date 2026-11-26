# System

> Status: built, not yet tested on every device. Feature folder: `lib/ui/features/system/`.

The **System** tab (4th of the 5 tabs: Download, Library, Convert, System, Settings; route `system`, child of the home shell) shows live device stats: RAM, CPU, GPU and network, one card each with the last minute as a sparkline. Only the metrics the running platform can report are shown. Nothing leaves the device.

## What Each Platform Reports

| Platform | RAM | CPU | GPU | Network | Source |
| --- | --- | --- | --- | --- | --- |
| Android | ✅ | — | — | ✅ (when `TrafficStats` is supported) | `ActivityManager.MemoryInfo` (total − available), `TrafficStats.getTotalRx/TxBytes`. Android hides `/proc/stat` and GPU load from apps. |
| iOS | ✅ | ✅ | — | ✅ | Mach `host_statistics64(HOST_VM_INFO64)` + `physicalMemory`, `host_statistics(HOST_CPU_LOAD_INFO)`, `getifaddrs` (interfaces that are up, loopback excluded) |
| macOS | ✅ | ✅ | ✅ (when a GPU driver reports it) | ✅ | Same as iOS, plus IOKit `IOAccelerator` → `PerformanceStatistics` "Device Utilization %" (highest across GPUs) |

- RAM "used" on iOS/macOS is counted like Activity Monitor: app memory + wired + compressed.
- CPU and network are whole-device, not just this app.
- Each native side decides its capabilities at runtime (e.g. macOS reports GPU only if a reading succeeds). A platform that reports nothing shows an empty state.

## Bridge

Pigeon input: `lib/config/pigeon/system_monitor_api.dart` (regenerate with `dart run pigeon --input lib/config/pigeon/system_monitor_api.dart`).

```dart
@HostApi()
abstract class SystemMonitorHostApi {
  SystemCapabilitiesMsg capabilities(); // memory, cpu, gpu, network: bool
  SystemSampleMsg sample();             // raw counters, null where unsupported
}
```

`SystemSampleMsg` carries **raw counters only**: `uptimeMillis` (monotonic), memory used/total, cumulative CPU busy/total ticks, instant `gpuPercent`, cumulative network rx/tx bytes. Native code keeps no state.

| Side | File |
| --- | --- |
| Dart client | `lib/core/clients/platform/system_monitor_api.g.dart` |
| Android | `android/app/src/main/kotlin/.../system/SystemMonitor.kt` (+ `SystemMonitorApi.g.kt`) |
| iOS | `ios/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |
| macOS | `macos/Runner/SystemMonitor/SystemMonitor.swift` (+ `SystemMonitorApi.g.swift`) |

The iOS and macOS `SystemMonitor.swift` files are identical copies (GPU code behind `#if os(macOS)`); keep them in sync by hand. Pigeon writes the Swift output to both folders, with its own error class name (`SystemMonitorPigeonError`) so it never clashes with other Pigeon files.

## Data Layer

- `SystemMonitorService` (`lib/data/services/platform/system_monitor/`): thin Pigeon wrapper; throws.
- `SystemMonitorRepositoryImpl`: wraps calls in `ErrorHandler` (`systemMonitor.metrics`, `systemMonitor.sample`), caches the metric list (`knownMetrics`) and keeps the previous raw sample.
- `SystemSampleMapper`: capabilities → `List<SystemMetric>` (order: memory, cpu, gpu, network); two raw samples → `SystemSample` with CPU % (busy delta / total delta) and download/upload bytes per second. Readings more than 5 s apart (the monitor was paused) or with a negative delta (32-bit counter wrapped, interface gone) give no rate for that second.

## Provider

| Provider | Owns | Notes |
| --- | --- | --- |
| `systemMonitorProvider` (`SystemMonitorNotifier`, `.autoDispose`) | `metrics`, `metricsKnown`, `latest` sample, `history` (≤ 60 samples, oldest first) | Polls `sample()` every **1 s**. Stops after 3 failed readings in a row. Failures stay in the error log only; the monitor never toasts. |

**Polling only while visible.** Tabs stay mounted in `AutoTabsRouter`, so `SystemScreen` watches the provider only when the System tab is the active tab, no route covers it, and the app is visible (`resumed` or `inactive`, `isAppVisible`). Otherwise it doesn't watch, the autoDispose notifier is disposed and its timer stops. The metric list is cached in the repository, so coming back doesn't flash the layout.

## Screen

```text
system/
  models/ monitor_visibility.dart, system_metric_display.dart   # label, body, icon, value formatting
  providers/system_monitor/ system_monitor_notifier.dart, system_monitor_state.dart
  views/system/
    system_screen.dart
    widgets/ metric_cards_grid.dart, system_metric_card.dart, gauge_metric_card.dart,
             network_metric_card.dart, network_speed_row.dart, metric_card_header.dart, sparkline.dart
```

- `MetricCardsGrid`: one column on phones, two (equal height per row) once two 320 px cards fit.
- **RAM / CPU / GPU** (`GaugeMetricCard`): percent, `GradientProgressBar`, RAM detail ("X of Y"), and a `Sparkline` fixed to 0–100%.
- **Network** (`NetworkMetricCard`): download and upload speed rows and a two-line sparkline (download in the Aurora gradient, upload thinner in the secondary colour), scaled to the busiest second shown. Speeds below 512 B/s read "0 KB/s" (`SystemMessages.idleSpeed`).
- `Sparkline`: a `CustomPainter` over 60 slots (one per second), newest at the right edge, caption "Last 60 seconds".
- States: shimmer cards until the capabilities are known; "—" for values until there are two readings; an empty state when the device reports none of the stats.

All text is in `SystemMessages` (`lib/core/messages/app_messages.dart`).

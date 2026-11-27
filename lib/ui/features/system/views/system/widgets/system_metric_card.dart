import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_hardware.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/speed_test.dart';
import 'package:media_tool/domain/models/speed_test_result.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/system/models/system_metric_display.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/bar_metric_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/gauge_metric_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/info_metric_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/network_metric_card.dart';
import 'package:media_tool/ui/features/system/views/system/widgets/speed_test_section.dart';

/// The System page card for [metric], from the latest reading and the last
/// minute of [history] (oldest first), or the latest [storage] / [battery],
/// plus [hardware] facts. Without [live] readings (CPU on Android, GPU on iOS)
/// it shows the facts only. RAM and Storage carry a speed test: the last
/// [speedResult], [runningTest] and [onSpeedTest] (null while one runs).
class const SystemMetricCard({
  super.key,
  required final SystemMetric metric,
  required final SystemSample? latest,
  required final List<SystemSample> history,
  final bool live = true,
  final DeviceStorage? storage,
  final BatteryStatus? battery,
  final DeviceHardware? hardware,
  final SpeedTestResult? speedResult,
  final SpeedTest? runningTest,
  final ValueChanged<SpeedTest>? onSpeedTest,
}) extends StatelessWidget {
  /// At or below this charge, on battery, the bar turns amber.
  static const _lowBatteryPercent = 20;

  Widget _speedTest(SpeedTest test, String note) => SpeedTestSection(
    note: note,
    results: SystemFormat.speedTest(speedResult),
    running: runningTest == test,
    onPressed: switch (onSpeedTest) {
      final run? when runningTest == null => () => run(test),
      _ => null,
    },
  );

  @override
  Widget build(BuildContext context) {
    if (!live) {
      return InfoMetricCard(
        icon: metric.icon,
        title: metric.label,
        body: metric.bodyFor(live: false),
        rows: switch (metric) {
          .cpu => SystemFormat.cpu(hardware),
          .gpu => SystemFormat.gpu(hardware),
          _ => const [],
        },
      );
    }
    switch (metric) {
      case .network:
        return NetworkMetricCard(
          icon: metric.icon,
          title: metric.label,
          body: metric.body,
          download: SystemFormat.speed(latest?.downloadBytesPerSecond),
          upload: SystemFormat.speed(latest?.uploadBytesPerSecond),
          downloadHistory: [for (final sample in history) ?sample.downloadBytesPerSecond],
          uploadHistory: [for (final sample in history) ?sample.uploadBytesPerSecond],
        );
      case .storage:
        final fraction = storage?.usedFraction;
        return BarMetricCard(
          icon: metric.icon,
          title: metric.label,
          body: metric.body,
          value: SystemFormat.fraction(fraction),
          fraction: fraction,
          rows: [
            (SystemMessages.storageUsed, SystemFormat.bytes(storage?.usedBytes)),
            (SystemMessages.storageFree, SystemFormat.bytes(storage?.freeBytes)),
            (SystemMessages.storageTotal, SystemFormat.bytes(storage?.totalBytes)),
            (SystemMessages.appFiles, SystemFormat.appShare(storage)),
            ...SystemFormat.drive(hardware),
          ],
          footer: _speedTest(.storage, SystemMessages.storageTestNote),
        );
      case .battery:
        final battery = this.battery;
        final fraction = battery == null ? null : battery.levelPercent / 100;
        final low = battery != null && battery.state == .discharging && battery.levelPercent <= _lowBatteryPercent;
        return BarMetricCard(
          icon: battery?.state == .charging ? Symbols.battery_charging_full_rounded : metric.icon,
          title: metric.label,
          body: metric.body,
          value: SystemFormat.fraction(fraction),
          fraction: fraction,
          barColor: low ? context.colors.warning : null,
          rows: [
            if (battery != null) ...[
              if (SystemFormat.batteryState(battery) case final state?) (SystemMessages.batteryStatus, state),
              ?SystemFormat.batteryTime(battery),
              if (battery.temperatureCelsius case final celsius?)
                (SystemMessages.batteryTemperature, SystemMessages.celsius(celsius)),
              if (SystemFormat.batteryHealthSummary(battery) case final health?) (SystemMessages.batteryHealth, health),
              if (battery.cycleCount case final cycles?) (SystemMessages.batteryCycles, '$cycles'),
              ...SystemFormat.batteryCapacity(battery),
            ],
          ],
        );
      case .memory || .cpu || .gpu:
        final fraction = metric.fractionOf(latest);
        return GaugeMetricCard(
          icon: metric.icon,
          title: metric.label,
          body: metric.body,
          value: SystemFormat.fraction(fraction),
          fraction: fraction,
          detail: metric == .memory ? SystemFormat.memoryDetail(latest) : null,
          history: [for (final sample in history) ?metric.fractionOf(sample)],
          rows: switch (metric) {
            .memory => SystemFormat.memory(hardware),
            .cpu => SystemFormat.cpu(hardware),
            _ => SystemFormat.gpu(hardware),
          },
          footer: metric == .memory ? _speedTest(.memory, SystemMessages.memoryTestNote) : null,
        );
    }
  }
}

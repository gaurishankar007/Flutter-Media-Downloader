import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/domain/models/system_metric.dart';
import 'package:media_downloader/domain/models/system_sample.dart';
import 'package:media_downloader/ui/features/system/models/system_metric_display.dart';
import 'package:media_downloader/ui/features/system/views/system/widgets/gauge_metric_card.dart';
import 'package:media_downloader/ui/features/system/views/system/widgets/network_metric_card.dart';

/// The System page card for [metric], from the latest reading and the last
/// minute of [history] (oldest first).
class const SystemMetricCard({
  super.key,
  required final SystemMetric metric,
  required final SystemSample? latest,
  required final List<SystemSample> history,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (metric == .network) {
      return NetworkMetricCard(
        icon: metric.icon,
        title: metric.label,
        body: metric.body,
        download: SystemFormat.speed(latest?.downloadBytesPerSecond),
        upload: SystemFormat.speed(latest?.uploadBytesPerSecond),
        downloadHistory: [for (final sample in history) ?sample.downloadBytesPerSecond],
        uploadHistory: [for (final sample in history) ?sample.uploadBytesPerSecond],
      );
    }
    final fraction = metric.fractionOf(latest);
    return GaugeMetricCard(
      icon: metric.icon,
      title: metric.label,
      body: metric.body,
      value: SystemFormat.fraction(fraction),
      fraction: fraction,
      detail: metric == .memory ? SystemFormat.memoryDetail(latest) : null,
      history: [for (final sample in history) ?metric.fractionOf(sample)],
    );
  }
}

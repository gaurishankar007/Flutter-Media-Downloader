import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/domain/models/system_metric.dart';
import 'package:media_downloader/domain/models/system_sample.dart';

/// Name, icon and values of a [SystemMetric] as the strip and page show them.
extension SystemMetricDisplay on SystemMetric {
  String get label => switch (this) {
    .memory => SystemMessages.memory,
    .cpu => SystemMessages.cpu,
    .gpu => SystemMessages.gpu,
    .network => SystemMessages.network,
  };

  String get body => switch (this) {
    .memory => SystemMessages.memoryBody,
    .cpu => SystemMessages.cpuBody,
    .gpu => SystemMessages.gpuBody,
    .network => SystemMessages.networkBody,
  };

  IconData get icon => switch (this) {
    .memory => Symbols.memory_alt_rounded,
    .cpu => Symbols.memory_rounded,
    .gpu => Symbols.view_in_ar_rounded,
    .network => Symbols.swap_vert_rounded,
  };

  /// Load as 0–1 for the gauge metrics; null for network or before a reading.
  double? fractionOf(SystemSample? sample) => switch (this) {
    .memory => sample?.memoryFraction,
    .cpu => _percentToFraction(sample?.cpuPercent),
    .gpu => _percentToFraction(sample?.gpuPercent),
    .network => null,
  };

  static double? _percentToFraction(double? percent) => percent == null ? null : percent / 100;
}

/// Text for live values; [SystemMessages.pending] until there's a reading.
abstract final class SystemFormat {
  static String fraction(double? value) => value == null ? SystemMessages.pending : SystemMessages.percent(value * 100);

  /// `FormatUtils.speed` rounds anything below 1 KB up; an idle link reads 0.
  static String speed(double? bytesPerSecond) => switch (bytesPerSecond) {
    null => SystemMessages.pending,
    < 512 => SystemMessages.idleSpeed,
    final value => FormatUtils.speed(value),
  };

  static String? memoryDetail(SystemSample? sample) => switch ((sample?.memoryUsedBytes, sample?.memoryTotalBytes)) {
    (final used?, final total?) => SystemMessages.memoryOf(FormatUtils.bytes(used), FormatUtils.bytes(total)),
    _ => null,
  };
}

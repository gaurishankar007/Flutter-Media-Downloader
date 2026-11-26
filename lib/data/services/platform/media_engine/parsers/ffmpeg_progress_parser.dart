import 'package:media_tool/domain/models/job_progress.dart';

/// Turns ffmpeg `-progress pipe:1` lines (`out_time_us=`, `speed=`) into a
/// [JobProgress] against the input's duration. One instance per run.
/// See docs/engine/media_engine.md#progress.
final class FfmpegProgressParser({final double? durationSeconds}) {
  double? _speed;

  /// The progress [line] reports, or null when it reports nothing.
  JobProgress? parse(String line) {
    if (line.startsWith('speed=')) {
      _speed = double.tryParse(line.substring('speed='.length).replaceAll('x', '').trim());
      return null;
    }
    final total = durationSeconds;
    if (!line.startsWith('out_time_us=') || total == null || total <= 0) {
      return null;
    }
    final micros = int.tryParse(line.substring('out_time_us='.length));
    if (micros == null || micros < 0) {
      return null;
    }
    final done = micros / 1e6;
    final speed = _speed;
    return JobProgress(
      stage: .processing,
      fraction: (done / total).clamp(0.0, 1.0),
      etaSeconds: speed == null || speed <= 0 ? null : ((total - done) / speed).clamp(0, double.infinity).round(),
    );
  }
}

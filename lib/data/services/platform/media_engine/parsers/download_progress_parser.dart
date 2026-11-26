import 'package:media_downloader/domain/models/job_progress.dart';

/// Turns yt-dlp / ffmpeg stdout lines into [JobProgress]. One instance per
/// job: it keeps state so a video + audio download reads as one bar that
/// never goes backwards. See docs/engine/media_engine.md#progress.
final class DownloadProgressParser({final int? expectedBytes, final int? durationSeconds}) {
  int _finishedStreamsBytes = 0;
  int _currentTotal = 0;
  int _currentDownloaded = 0;
  double _lastFraction = 0;

  static const _steps = {
    '[Merger]': ProcessingStep.merging,
    '[ExtractAudio]': ProcessingStep.extractingAudio,
    '[VideoRemuxer]': ProcessingStep.finishing,
    '[VideoConvertor]': ProcessingStep.finishing,
    '[EmbedThumbnail]': ProcessingStep.finishing,
    '[Metadata]': ProcessingStep.finishing,
    '[FixupM3u8]': ProcessingStep.finishing,
  };

  /// The progress [line] reports, or `null` when it reports nothing.
  JobProgress? parseYtDlp(String line) {
    if (line.startsWith('[MD]')) {
      return _download(line.substring(4).split('|'));
    }
    // A new stream (video, then audio) starts: bank the previous one's bytes.
    if (line.startsWith('[download] Destination:') && _currentTotal > 0) {
      _finishedStreamsBytes += _currentTotal;
      _currentTotal = 0;
      _currentDownloaded = 0;
      return null;
    }
    for (final MapEntry(key: prefix, value: step) in _steps.entries) {
      if (line.startsWith(prefix)) {
        return JobProgress(stage: .processing, step: step);
      }
    }
    return null;
  }

  /// ffmpeg `-progress pipe:1` lines against the input's duration.
  JobProgress? parseFfmpeg(String line, {required ProcessingStep step}) {
    if (!line.startsWith('out_time_us=') || durationSeconds == null || durationSeconds == 0) {
      return null;
    }
    final micros = int.tryParse(line.substring('out_time_us='.length));
    if (micros == null) {
      return null;
    }
    final fraction = (micros / 1e6 / durationSeconds!).clamp(0.0, 1.0);
    return JobProgress(stage: .processing, step: step, fraction: fraction);
  }

  JobProgress _download(List<String> fields) {
    int? asInt(int index) => index < fields.length ? double.tryParse(fields[index])?.round() : null;
    final downloaded = asInt(0) ?? 0;
    final total = asInt(1) ?? asInt(2) ?? 0;
    final speed = fields.length > 3 ? double.tryParse(fields[3]) : null;
    final eta = asInt(4);
    _currentDownloaded = downloaded;
    _currentTotal = total;

    final done = _finishedStreamsBytes + _currentDownloaded;
    final whole = [expectedBytes ?? 0, _finishedStreamsBytes + _currentTotal].reduce((a, b) => a > b ? a : b);
    if (whole > 0) {
      _lastFraction = [_lastFraction, (done / whole).clamp(0.0, 1.0)].reduce((a, b) => a > b ? a : b);
    }
    return JobProgress(
      stage: .downloading,
      fraction: whole > 0 ? _lastFraction : null,
      speedBytesPerSecond: speed,
      etaSeconds: eta,
    );
  }
}

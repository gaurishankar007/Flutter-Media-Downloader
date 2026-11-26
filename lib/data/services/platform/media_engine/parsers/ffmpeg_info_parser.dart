import 'package:media_downloader/data/models/responses/local_media_info_dto.dart';

/// Reads the input summary ffmpeg prints to stderr for `ffmpeg -i <file>`:
///
/// ```text
/// Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'in.mp4':
///   Duration: 00:03:32.53, start: 0.000000, bitrate: 4120 kb/s
///   Stream #0:0[0x1](und): Video: h264 (High) (avc1 / 0x31637661), yuv420p, 1920x1080 [SAR 1:1 DAR 16:9], …
///     Side data:
///       displaymatrix: rotation of -90.00 degrees
///   Stream #0:1[0x2](und): Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 128 kb/s (default)
/// ```
abstract final class FfmpegInfoParser {
  static final _duration = RegExp(r'Duration: (\d+):(\d{2}):(\d{2}(?:\.\d+)?)');
  static final _video = RegExp(r'Stream #\d+:\d+.*?: Video: (\w+)');
  static final _audio = RegExp(r'Stream #\d+:\d+.*?: Audio: (\w+)');
  static final _size = RegExp(r', (\d{2,5})x(\d{2,5})\b');
  static final _kbps = RegExp(r'(\d+) kb/s');
  static final _rotation = RegExp(r'rotation of (-?\d+(?:\.\d+)?) degrees|rotate\s*:\s*(-?\d+)');

  /// The file's info, or null when ffmpeg couldn't read it as media.
  static LocalMediaInfoDto? parse(String output) {
    if (!output.contains('Input #0')) {
      return null;
    }
    double? duration;
    int? width;
    int? height;
    String? videoCodec;
    String? audioCodec;
    int? audioKbps;
    var inVideo = false;

    for (final line in output.split('\n')) {
      if (_duration.firstMatch(line) case final match? when duration == null) {
        duration = int.parse(match.group(1)!) * 3600 + int.parse(match.group(2)!) * 60 + double.parse(match.group(3)!);
        continue;
      }
      if (line.contains('Stream #')) {
        inVideo = false;
      }
      // Cover art in MP3 / M4A shows up as a video stream.
      if (_video.firstMatch(line) case final match? when videoCodec == null && !line.contains('attached pic')) {
        videoCodec = match.group(1);
        if (_size.firstMatch(line) case final size?) {
          width = int.parse(size.group(1)!);
          height = int.parse(size.group(2)!);
        }
        inVideo = true;
        continue;
      }
      if (_audio.firstMatch(line) case final match? when audioCodec == null) {
        audioCodec = match.group(1);
        audioKbps = int.tryParse(_kbps.firstMatch(line)?.group(1) ?? '');
        continue;
      }
      // Phone videos are often stored sideways with a rotation flag.
      if (_rotation.firstMatch(line) case final match? when inVideo && width != null) {
        final degrees = double.parse(match.group(1) ?? match.group(2)!).round().abs() % 180;
        if (degrees == 90) {
          (width, height) = (height, width);
        }
        inVideo = false;
      }
    }
    return LocalMediaInfoDto(
      durationSeconds: duration,
      width: width,
      height: height,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      audioKbps: audioKbps,
    );
  }
}

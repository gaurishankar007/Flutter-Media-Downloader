import 'package:media_downloader/core/types/types.dart';

/// The parts of `yt-dlp -J` the app uses. See docs/engine/media_engine.md#probe.
final class const ProbeResponseDto({
  required final String title,
  final String? uploader,
  final double? duration,
  final String? thumbnail,
  final List<FormatDto> formats = const [],
}) {
  /// A playlist (Instagram carousel, X thread) uses its first entry with formats.
  factory fromJson(JsonMap json) {
    if (json case {'_type': 'playlist', 'entries': final List<dynamic> entries}) {
      final withFormats = entries.whereType<JsonMap>().where((entry) => entry['formats'] is List).firstOrNull;
      if (withFormats != null) {
        return ProbeResponseDto.fromJson({...withFormats, 'title': withFormats['title'] ?? json['title']});
      }
    }
    return ProbeResponseDto(
      title: (json['title'] ?? json['fulltitle'] ?? json['id'] ?? '') as String,
      uploader: (json['uploader'] ?? json['channel'] ?? json['uploader_id']) as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      thumbnail: json['thumbnail'] as String?,
      formats: [
        for (final format in (json['formats'] as List<dynamic>? ?? const []).whereType<JsonMap>())
          FormatDto.fromJson(format),
      ],
    );
  }
}

/// One entry of `formats`.
final class const FormatDto({
  final String? vcodec,
  final String? acodec,
  final int? width,
  final int? height,
  final int? filesize,
  final int? filesizeApprox,

  /// Total / audio bitrate in kbps.
  final double? tbr,
  final double? abr,

  /// Direct media URL, transfer protocol and the headers it needs.
  final String? url,
  final String? protocol,
  final Map<String, String> httpHeaders = const {},
}) {
  factory fromJson(JsonMap json) => FormatDto(
    vcodec: json['vcodec'] as String?,
    acodec: json['acodec'] as String?,
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    filesize: (json['filesize'] as num?)?.toInt(),
    filesizeApprox: (json['filesize_approx'] as num?)?.toInt(),
    tbr: (json['tbr'] as num?)?.toDouble(),
    abr: (json['abr'] as num?)?.toDouble(),
    url: json['url'] as String?,
    protocol: json['protocol'] as String?,
    httpHeaders: {
      if (json['http_headers'] case final JsonMap headers)
        for (final MapEntry(:key, :value) in headers.entries)
          if (value is String) key: value,
    },
  );

  /// Has video and audio in one file over plain HTTP(S), so a player can stream it.
  bool get isProgressive => hasVideo && hasAudio && url != null && (protocol == 'https' || protocol == 'http');

  bool get hasVideo => vcodec != 'none' && height != null;

  bool get hasAudio => acodec != null && acodec != 'none';

  bool get isAudioOnly => vcodec == 'none' && hasAudio;

  bool get isH264 => vcodec != null && (vcodec!.startsWith('avc1') || vcodec!.startsWith('h264'));

  /// The short side, so vertical videos get the same tier as landscape ones.
  int? get resolution => switch ((width, height)) {
    (final int w, final int h) => w < h ? w : h,
    (_, final int h) => h,
    _ => null,
  };

  /// Reported size, or an estimate from bitrate × [durationSeconds].
  int? sizeFor(double? durationSeconds) =>
      filesize ??
      filesizeApprox ??
      (tbr != null && durationSeconds != null ? (tbr! * 1000 / 8 * durationSeconds).round() : null);
}

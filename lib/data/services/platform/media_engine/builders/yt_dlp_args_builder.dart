import 'package:media_downloader/domain/models/cookie_browser.dart';
import 'package:media_downloader/domain/models/download_request.dart';
import 'package:path/path.dart' as p;

/// Builds every yt-dlp command line. Platform engines only run them. See
/// docs/engine/media_engine.md#download-args and docs/engine/ffmpeg_recipes.md.
abstract final class YtDlpArgsBuilder {
  /// Media and thumbnail names inside a job's work folder.
  static const mediaStem = 'media';
  static const thumbnailStem = 'thumb';

  static const _progressTemplate =
      'download:[MD]%(progress.downloaded_bytes)s|%(progress.total_bytes)s|'
      '%(progress.total_bytes_estimate)s|%(progress.speed)s|%(progress.eta)s';

  static List<String> probe(String url, {String? cookiesPath, CookieBrowser browser = .none}) => [
    '-J',
    '--no-playlist',
    '--no-warnings',
    ..._cookies(cookiesPath, browser),
    url,
  ];

  static List<String> download(
    DownloadRequest request, {
    required String workDir,
    String? cookiesPath,
    CookieBrowser browser = .none,
  }) => [
    '--newline',
    '--no-playlist',
    '--no-mtime',
    '--no-warnings',
    '--progress-template',
    _progressTemplate,
    '-o',
    p.join(workDir, '$mediaStem.%(ext)s'),
    '-o',
    'thumbnail:${p.join(workDir, '$thumbnailStem.%(ext)s')}',
    '--write-thumbnail',
    '--convert-thumbnails',
    'jpg',
    ..._cookies(cookiesPath, browser),
    ...switch (request.kind) {
      .audio => _audio(request),
      _ => _video(request),
    },
    request.url,
  ];

  /// The site's own cookies.txt wins over browser cookies (macOS only).
  static List<String> _cookies(String? cookiesPath, CookieBrowser browser) =>
      switch ((cookiesPath, browser.ytDlpName)) {
        (final path?, _) => ['--cookies', path],
        (null, final name?) => ['--cookies-from-browser', name],
        _ => const [],
      };

  static List<String> _video(DownloadRequest request) {
    final cap = request.height == null ? '' : '[height<=${request.height}]';
    if (!request.iphoneCompatible) {
      return ['-f', 'bv*$cap+ba/b$cap/b', '--merge-output-format', 'mp4/mkv'];
    }
    if (request.needsReencode) {
      // No H.264 at this height: take the best streams, re-encode afterwards.
      return ['-f', 'bv*$cap+ba/b$cap/b', '--merge-output-format', 'mkv'];
    }
    // H.264 + AAC so the MP4 is only a remux.
    return [
      '-f',
      'bv*$cap[vcodec^=avc1]+ba[ext=m4a]/bv*$cap[vcodec^=avc1]+ba/b$cap[vcodec^=avc1]/bv*$cap+ba/b$cap/b',
      '--merge-output-format',
      'mp4',
    ];
  }

  static List<String> _audio(DownloadRequest request) => [
    '-f',
    'ba/b',
    '-x',
    '--audio-format',
    'mp3',
    '--audio-quality',
    '${request.audioQuality.kbps}K',
    '--embed-thumbnail',
    '--add-metadata',
  ];
}

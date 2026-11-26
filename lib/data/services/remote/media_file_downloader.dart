import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:media_downloader/data/services/remote/site_http_client.dart';
import 'package:path/path.dart' as p;

/// Downloads a post's photos and videos straight from their CDN URLs (no
/// engine, no cookies). Methods throw; the repository wraps them.
/// See docs/extractors/photo_extractors.md#downloading-the-images.
@lazySingleton
final class MediaFileDownloader({required final SiteHttpClient _http}) {
  static const _extensions = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/heic': 'heic',
    'image/heif': 'heic',
    'image/gif': 'gif',
    'image/avif': 'avif',
    'video/mp4': 'mp4',
    'video/quicktime': 'mov',
    'video/webm': 'webm',
    'audio/mpeg': 'mp3',
    'audio/mp4': 'm4a',
    'audio/aac': 'aac',
  };

  final _tokens = <String, CancelToken>{};

  /// Downloads [url] into [directory] as `[stem].<ext>`, the extension taken
  /// from the response's type (CDN URLs often have none). Returns the path.
  Future<String> download(
    String jobId,
    Uri url, {
    required String directory,
    required String stem,
    required String fallbackExtension,
    Map<String, String> headers = const {},
    void Function(int received, int total)? onProgress,
  }) async {
    await Directory(directory).create(recursive: true);
    final partial = p.join(directory, '$stem.part');
    final responseHeaders = await _http.download(
      url,
      partial,
      cancelToken: _tokens.putIfAbsent(jobId, CancelToken.new),
      onReceiveProgress: onProgress,
      headers: headers,
    );
    final type = responseHeaders.value(Headers.contentTypeHeader)?.split(';').first.trim().toLowerCase();
    final fromUrl = p.extension(url.path).replaceFirst('.', '').toLowerCase();
    final extension = _extensions[type] ?? (_extensions.containsValue(fromUrl) ? fromUrl : fallbackExtension);
    final target = p.join(directory, '$stem.$extension');
    await File(partial).rename(target);
    return target;
  }

  /// Stops [jobId]'s download; later calls for it fail at once.
  void cancel(String jobId) => _tokens.putIfAbsent(jobId, CancelToken.new).cancel();

  bool isCancelled(String jobId) => _tokens[jobId]?.isCancelled ?? false;

  /// Forgets [jobId] once its run is over.
  void release(String jobId) => _tokens.remove(jobId);
}

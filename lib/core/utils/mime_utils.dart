import 'package:path/path.dart' as p;

/// MIME types of the formats the app writes, for Save to Files.
abstract final class MimeUtils {
  static const _byExtension = {
    'mp4': 'video/mp4',
    'm4v': 'video/mp4',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    'mov': 'video/quicktime',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'opus': 'audio/ogg',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'gif': 'image/gif',
  };

  static String forPath(String path) =>
      _byExtension[p.extension(path).replaceFirst('.', '').toLowerCase()] ?? 'application/octet-stream';
}

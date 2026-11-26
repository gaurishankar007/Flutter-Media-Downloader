import 'package:media_downloader/domain/models/media_kind.dart';

/// A format the converter writes. See docs/features/convert.md#formats.
enum ConvertFormat {
  mp4('mp4', 'MP4', .video),
  mov('mov', 'MOV', .video),
  mkv('mkv', 'MKV', .video),
  webm('webm', 'WebM', .video),
  mp3('mp3', 'MP3', .audio),
  m4a('m4a', 'M4A', .audio),
  jpg('jpg', 'JPG', .photo),
  png('png', 'PNG', .photo),
  webp('webp', 'WebP', .photo),
  heic('heic', 'HEIC', .photo);

  new(this.extension, this.label, this.kind);

  final String extension;
  final String label;

  /// What the output file is (video → MP3 makes audio).
  final MediaKind kind;

  /// The format a file extension stands for (`jpeg` → jpg, `m4v` → mp4), or null.
  static ConvertFormat? fromExtension(String extension) => switch (extension.toLowerCase()) {
    'jpeg' => jpg,
    'heif' => heic,
    'm4v' => mp4,
    final other => values.where((format) => format.extension == other).firstOrNull,
  };
}

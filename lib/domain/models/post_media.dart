import 'package:equatable/equatable.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/media_kind.dart';

/// One photo or video of a post found by a photo extractor, downloaded
/// directly (no engine). See docs/extractors/photo_extractors.md.
final class const PostMedia({
  required final String url,

  /// [MediaKind.photo] or [MediaKind.video].
  required final MediaKind kind,
  final int? width,
  final int? height,

  /// A small image for the preview grid; the photo itself when null.
  final String? thumbnailUrl,
}) extends Equatable {
  factory fromJson(JsonMap json) => PostMedia(
    url: json['url'] as String,
    kind: MediaKind.values.asNameMap()[json['kind']] ?? .photo,
    width: json['width'] as int?,
    height: json['height'] as int?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
  );

  /// What the preview grid shows.
  String? get previewUrl => thumbnailUrl ?? (kind == .photo ? url : null);

  JsonMap toJson() => {'url': url, 'kind': kind.name, 'width': width, 'height': height, 'thumbnailUrl': thumbnailUrl};

  @override
  List<Object?> get props => [url, kind, width, height, thumbnailUrl];
}

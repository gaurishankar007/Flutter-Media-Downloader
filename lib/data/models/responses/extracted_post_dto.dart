/// One photo or video a photo extractor found.
final class const ExtractedMediaDto({
  required final String url,
  required final bool isVideo,
  final int? width,
  final int? height,

  /// Videos: a still for the preview.
  final String? thumbnailUrl,
});

/// What a photo extractor read from a post page. See
/// docs/extractors/photo_extractors.md#interface.
final class const ExtractedPostDto({
  required final String postId,
  required final List<ExtractedMediaDto> media,
  final String? author,
  final String? caption,

  /// TikTok slideshows.
  final String? musicUrl,
});

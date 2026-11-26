import 'package:media_tool/data/models/responses/extracted_post_dto.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/post_media.dart';
import 'package:media_tool/domain/models/preview_stream.dart';
import 'package:media_tool/domain/models/site.dart';

/// A photo extractor's [ExtractedPostDto] → the [MediaInfo] the preview shows.
/// See docs/extractors/photo_extractors.md#interface.
abstract final class PostMapper {
  static const _maxTitleLength = 100;

  static MediaInfo fromDto(ExtractedPostDto dto, {required String url, required Site site}) {
    final media = [
      for (final item in dto.media)
        PostMedia(
          url: item.url,
          kind: item.isVideo ? .video : .photo,
          width: item.width,
          height: item.height,
          thumbnailUrl: item.thumbnailUrl,
        ),
    ];
    final onlyVideo = media.length == 1 && media.first.kind == .video ? media.first : null;
    return MediaInfo(
      url: url,
      site: site,
      title: _title(dto, site),
      uploader: dto.author,
      thumbnailUrl: media.map((item) => item.previewUrl).nonNulls.firstOrNull,
      hasAudio: false,
      // A single direct video can play inline.
      previewStream: onlyVideo == null ? null : PreviewStream(url: onlyVideo.url),
      postId: dto.postId.isEmpty ? null : dto.postId,
      postMedia: media,
      musicUrl: dto.musicUrl,
    );
  }

  /// The caption's first line, else the author, else the site.
  static String _title(ExtractedPostDto dto, Site site) {
    final caption = dto.caption?.trim().split('\n').first.trim() ?? '';
    if (caption.isNotEmpty) {
      return caption.length > _maxTitleLength ? '${caption.substring(0, _maxTitleLength).trim()}…' : caption;
    }
    if (dto.author case final author? when author.isNotEmpty) {
      return '@$author';
    }
    return site.label;
  }
}

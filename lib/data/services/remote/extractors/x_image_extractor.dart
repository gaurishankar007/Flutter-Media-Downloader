import 'package:injectable/injectable.dart';
import 'package:media_tool/core/errors/extractor_errors.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/extracted_post_dto.dart';
import 'package:media_tool/data/services/remote/extractors/extractor_html.dart';
import 'package:media_tool/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_tool/data/services/remote/site_http_client.dart';
import 'package:media_tool/domain/models/site.dart';

/// Tweet images (and a tweet's videos alongside them) from X's public
/// embed data, at full size (`name=orig`).
/// See docs/extractors/photo_extractors.md#x-images.
@lazySingleton
final class XImageExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  static final _statusId = RegExp(r'/status(?:es)?/(\d+)');

  /// The embed endpoint asks for a token but accepts any value (checked
  /// 2026-11-25).
  static const _token = 'a';

  @override
  Site get site => .x;

  @override
  bool canHandle(Uri url) => _statusId.hasMatch(url.path);

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    final id = _statusId.firstMatch(url.path)?.group(1);
    if (id == null) {
      throw ExtractorException(.noMedia, site: site, detail: 'no status id');
    }
    // A twimg.com host, so no X cookies go along.
    final tweet = await _http.getJson(
      Uri.https('cdn.syndication.twimg.com', '/tweet-result', {'id': id, 'lang': 'en', 'token': _token}),
    );
    if (tweet == null || tweet['__typename'] == 'TweetTombstone' || tweet['id_str'] == null) {
      throw ExtractorException(.notFound, site: site, detail: 'tweet unavailable');
    }

    final details = tweet['mediaDetails'];
    final media = <ExtractedMediaDto>[
      if (details is List)
        for (final detail in details.whereType<JsonMap>()) ?_media(detail),
    ];
    if (media.isEmpty) {
      throw ExtractorException(.noMedia, site: site, detail: 'tweet has no media');
    }
    return ExtractedPostDto(
      postId: id,
      media: media,
      author: ExtractorHtml.at(tweet, ['user', 'screen_name']) as String?,
      caption: tweet['text'] as String?,
    );
  }

  static ExtractedMediaDto? _media(JsonMap detail) {
    final still = detail['media_url_https'] as String?;
    final width = ExtractorHtml.asInt(ExtractorHtml.at(detail, ['original_info', 'width']));
    final height = ExtractorHtml.asInt(ExtractorHtml.at(detail, ['original_info', 'height']));
    if (detail['type'] == 'photo') {
      return still == null
          ? null
          : ExtractedMediaDto(url: _original(still), isVideo: false, width: width, height: height, thumbnailUrl: still);
    }
    // video / animated_gif: the highest-bitrate MP4.
    final variants = ExtractorHtml.at(detail, ['video_info', 'variants']);
    final mp4s = [
      if (variants is List)
        for (final variant in variants.whereType<JsonMap>())
          if (variant['content_type'] == 'video/mp4' && variant['url'] is String) variant,
    ];
    if (mp4s.isEmpty) {
      return null;
    }
    final best = mp4s.reduce(
      (a, b) => (ExtractorHtml.asInt(a['bitrate']) ?? 0) >= (ExtractorHtml.asInt(b['bitrate']) ?? 0) ? a : b,
    );
    return ExtractedMediaDto(
      url: best['url'] as String,
      isVideo: true,
      width: width,
      height: height,
      thumbnailUrl: still,
    );
  }

  /// `pbs.twimg.com/media/…` in full size.
  static String _original(String url) {
    final uri = Uri.parse(url);
    if (uri.host != 'pbs.twimg.com') {
      return url;
    }
    final extension = uri.path.contains('.') ? uri.path.split('.').last : 'jpg';
    final path = uri.path.contains('.') ? uri.path.substring(0, uri.path.lastIndexOf('.')) : uri.path;
    return Uri.https(uri.host, path, {'format': extension, 'name': 'orig'}).toString();
  }
}

import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/errors/extractor_errors.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/data/models/responses/extracted_post_dto.dart';
import 'package:media_downloader/data/services/remote/extractors/extractor_html.dart';
import 'package:media_downloader/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_downloader/data/services/remote/site_http_client.dart';
import 'package:media_downloader/domain/models/site.dart';

/// Threads posts: images, videos and carousels. yt-dlp has no Threads
/// extractor, so videos come from here too. Expect breakage when Meta changes
/// the page. See docs/extractors/photo_extractors.md#threads.
@lazySingleton
final class ThreadsExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  static final _code = RegExp('/post/([A-Za-z0-9_-]+)');

  @override
  Site get site => .threads;

  @override
  bool canHandle(Uri url) => _code.hasMatch(url.path);

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    final code = _code.firstMatch(url.path)?.group(1);
    if (code == null) {
      throw ExtractorException(.noMedia, site: site, detail: 'no post code');
    }
    final page = await _http.getText(url, site: site);
    final document = ExtractorHtml.parse(page.body);

    // The post object in the embedded JSON: `code` plus its media.
    JsonMap? post;
    for (final script in ExtractorHtml.jsonScripts(document)) {
      post = ExtractorHtml.objects(script).where((object) => object['code'] == code && _hasMedia(object)).firstOrNull;
      if (post != null) {
        break;
      }
    }

    final media = <ExtractedMediaDto>[];
    if (post != null) {
      final carousel = post['carousel_media'];
      final items = carousel is List && carousel.isNotEmpty ? carousel.whereType<JsonMap>() : [post];
      media.addAll([for (final item in items) ?_item(item)]);
    }
    if (media.isEmpty) {
      // Meta tags: enough for a single image or video.
      if (ExtractorHtml.meta(document, 'og:video') case final video?) {
        media.add(ExtractedMediaDto(url: video, isVideo: true, thumbnailUrl: ExtractorHtml.meta(document, 'og:image')));
      } else if (ExtractorHtml.meta(document, 'og:image') case final image? when post != null) {
        media.add(ExtractedMediaDto(url: image, isVideo: false));
      }
    }
    if (media.isEmpty) {
      throw ExtractorException(post == null ? .notFound : .noMedia, site: site, detail: 'no media for the post');
    }
    return ExtractedPostDto(
      postId: code,
      media: media,
      author: ExtractorHtml.at(post, ['user', 'username']) as String?,
      caption: ExtractorHtml.at(post, ['caption', 'text']) as String?,
    );
  }

  static bool _hasMedia(JsonMap object) =>
      object['image_versions2'] is JsonMap || object['carousel_media'] is List || object['video_versions'] is List;

  static ExtractedMediaDto? _item(JsonMap item) {
    final candidates = ExtractorHtml.at(item, ['image_versions2', 'candidates']);
    final images = candidates is List ? candidates.whereType<JsonMap>().toList() : <JsonMap>[];
    final best = images.isEmpty
        ? null
        : images.reduce(
            (a, b) => (ExtractorHtml.asInt(a['width']) ?? 0) >= (ExtractorHtml.asInt(b['width']) ?? 0) ? a : b,
          );
    final still = best?['url'] as String?;
    final width = ExtractorHtml.asInt(item['original_width']) ?? ExtractorHtml.asInt(best?['width']);
    final height = ExtractorHtml.asInt(item['original_height']) ?? ExtractorHtml.asInt(best?['height']);

    final videos = item['video_versions'];
    if (videos is List && videos.isNotEmpty) {
      final url = ExtractorHtml.at(videos.first, ['url']) as String?;
      if (url != null) {
        return ExtractedMediaDto(url: url, isVideo: true, width: width, height: height, thumbnailUrl: still);
      }
    }
    return still == null ? null : ExtractedMediaDto(url: still, isVideo: false, width: width, height: height);
  }
}

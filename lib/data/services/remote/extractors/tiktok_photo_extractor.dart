import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/errors/extractor_errors.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/data/models/responses/extracted_post_dto.dart';
import 'package:media_downloader/data/services/remote/extractors/extractor_html.dart';
import 'package:media_downloader/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_downloader/data/services/remote/site_http_client.dart';
import 'package:media_downloader/domain/models/site.dart';

/// TikTok photo posts (slideshows) from the page's rehydration JSON.
/// See docs/extractors/photo_extractors.md#tiktok-photo-posts-slideshows.
@lazySingleton
final class TikTokPhotoExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  static const _dataScriptId = '__UNIVERSAL_DATA_FOR_REHYDRATION__';

  /// Where the post sits in that JSON. TikTok moves it now and then: check a
  /// live post and update this one constant.
  static const _itemPath = ['__DEFAULT_SCOPE__', 'webapp.video-detail', 'itemInfo', 'itemStruct'];
  static const _statusPath = ['__DEFAULT_SCOPE__', 'webapp.video-detail', 'statusCode'];
  static final _postId = RegExp(r'/(?:photo|video)/(\d+)');

  @override
  Site get site => .tiktok;

  @override
  bool canHandle(Uri url) => _postId.hasMatch(url.path);

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    final page = await _http.getText(url, site: site);
    final data = ExtractorHtml.scriptJson(ExtractorHtml.parse(page.body), _dataScriptId);
    if (data == null) {
      throw ExtractorException(.broken, site: site, detail: 'no $_dataScriptId script');
    }
    final item = ExtractorHtml.at(data, _itemPath);
    if (item is! JsonMap) {
      final status = ExtractorHtml.at(data, _statusPath);
      throw ExtractorException(
        status == null ? .broken : .notFound,
        site: site,
        detail: 'no itemStruct, statusCode $status',
      );
    }

    final images = ExtractorHtml.at(item, ['imagePost', 'images']);
    final media = <ExtractedMediaDto>[
      if (images is List)
        for (final image in images.whereType<JsonMap>())
          if (ExtractorHtml.at(image, ['imageURL', 'urlList']) case [final String first, ...])
            ExtractedMediaDto(
              // The first URL of each image, in order.
              url: first,
              isVideo: false,
              width: ExtractorHtml.asInt(image['imageWidth']),
              height: ExtractorHtml.asInt(image['imageHeight']),
            ),
    ];
    if (media.isEmpty) {
      throw ExtractorException(.noMedia, site: site, detail: 'itemStruct has no imagePost');
    }
    return ExtractedPostDto(
      postId: '${item['id'] ?? _postId.firstMatch(page.url.path)?.group(1) ?? ''}',
      media: media,
      author: ExtractorHtml.at(item, ['author', 'uniqueId']) as String?,
      caption: item['desc'] as String?,
      musicUrl: ExtractorHtml.at(item, ['music', 'playUrl']) as String?,
    );
  }
}

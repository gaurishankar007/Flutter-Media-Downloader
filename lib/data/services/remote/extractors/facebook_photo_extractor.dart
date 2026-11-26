import 'package:html/dom.dart';
import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/errors/extractor_errors.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/data/models/responses/extracted_post_dto.dart';
import 'package:media_downloader/data/services/remote/extractors/extractor_html.dart';
import 'package:media_downloader/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_downloader/data/services/remote/site_http_client.dart';
import 'package:media_downloader/domain/models/site.dart';

/// Facebook single photos, albums and multi-photo posts: `og:image` for one
/// photo, the page's embedded JSON for several. Many need a login (cookies).
/// See docs/extractors/photo_extractors.md#facebook-photos.
@lazySingleton
final class FacebookPhotoExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  /// JSON keys holding a full-size photo `{uri, width, height}`.
  static const _imageKeys = ['viewer_image', 'photo_image'];
  static final _numbers = RegExp(r'\d{6,}');

  @override
  Site get site => .facebook;

  @override
  bool canHandle(Uri url) => true;

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    // The desktop page first; some posts only render for a mobile browser.
    for (final mobile in [false, true]) {
      final page = await _http.getText(url, site: site, mobile: mobile);
      if (page.url.path.contains('/login')) {
        break;
      }
      final document = ExtractorHtml.parse(page.body);
      final media = _fromJson(document);
      if (media.isEmpty) {
        if (ExtractorHtml.meta(document, 'og:image') case final image?) {
          media.add(ExtractedMediaDto(url: image, isVideo: false));
        }
      }
      if (media.isNotEmpty) {
        return ExtractedPostDto(
          postId: _postId(page.url) ?? _postId(url) ?? '',
          media: media,
          caption: ExtractorHtml.meta(document, 'og:description') ?? ExtractorHtml.meta(document, 'og:title'),
        );
      }
    }
    throw ExtractorException(
      cookiesPath == null ? .loginRequired : .noMedia,
      site: site,
      detail: 'no photos on the page',
    );
  }

  /// Full-size photos from the page's JSON, in order, without duplicates.
  static List<ExtractedMediaDto> _fromJson(Document document) {
    final seen = <String>{};
    final media = <ExtractedMediaDto>[];
    for (final script in ExtractorHtml.jsonScripts(document)) {
      for (final object in ExtractorHtml.objects(script)) {
        for (final key in _imageKeys) {
          if (object[key] case final JsonMap image) {
            final uri = image['uri'] as String?;
            // The same photo shows up under several keys with different signatures.
            if (uri == null || !seen.add(Uri.tryParse(uri)?.path ?? uri)) {
              continue;
            }
            media.add(
              ExtractedMediaDto(
                url: uri,
                isVideo: false,
                width: ExtractorHtml.asInt(image['width']),
                height: ExtractorHtml.asInt(image['height']),
              ),
            );
          }
        }
      }
    }
    return media;
  }

  /// `fbid=`, `story_fbid=`, or the last long number in the path.
  static String? _postId(Uri url) =>
      url.queryParameters['fbid'] ??
      url.queryParameters['story_fbid'] ??
      _numbers.allMatches(url.path).lastOrNull?.group(0);
}

import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/errors/extractor_errors.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/extracted_post_dto.dart';
import 'package:media_tool/data/services/remote/extractors/extractor_html.dart';
import 'package:media_tool/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_tool/data/services/remote/site_http_client.dart';
import 'package:media_tool/domain/models/site.dart';

/// YouTube channel posts (formerly "Community") with one or more images.
/// yt-dlp doesn't read posts. The post page embeds `ytInitialData`, which has
/// a `backstagePostRenderer` with the images. See
/// docs/extractors/photo_extractors.md#youtube-posts.
@lazySingleton
final class YouTubePostExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  static final _postPath = RegExp('^/post/([A-Za-z0-9_-]+)');
  static const _initialData = 'var ytInitialData = ';

  @override
  Site get site => .youtube;

  @override
  bool canHandle(Uri url) => postId(url) != null;

  /// The post id of `/post/<id>` or a channel's `…/community?lb=<id>` link.
  static String? postId(Uri url) => _postPath.firstMatch(url.path)?.group(1) ?? url.queryParameters['lb'];

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    final id = postId(url);
    if (id == null) {
      throw ExtractorException(.noMedia, site: site, detail: 'no post id');
    }
    final page = await _http.getText(Uri.https('www.youtube.com', '/post/$id'), site: site);
    return parse(page.body, id);
  }

  /// The post's images from a `/post/<id>` page.
  static ExtractedPostDto parse(String body, String id) {
    final post = ExtractorHtml.objects(_ytInitialData(body))
        .map((object) => object['backstagePostRenderer'])
        .whereType<JsonMap>()
        .firstOrNull;
    if (post == null) {
      throw const ExtractorException(.notFound, site: .youtube, detail: 'no backstagePostRenderer');
    }

    // One image: backstageImageRenderer; several: postMultiImageRenderer.images[].
    final attachment = post['backstageAttachment'];
    final media = <ExtractedMediaDto>[
      for (final image in ExtractorHtml.objects(attachment))
        if (image['backstageImageRenderer'] case final JsonMap renderer) ?_image(renderer),
    ];
    if (media.isEmpty) {
      throw const ExtractorException(.noMedia, site: .youtube, detail: 'post has no images');
    }
    return ExtractedPostDto(
      postId: id,
      media: media,
      author: _text(post['authorText']),
      caption: _text(post['contentText']),
    );
  }

  static Object? _ytInitialData(String body) {
    for (final script in ExtractorHtml.parse(body).querySelectorAll('script')) {
      final text = script.text.trim();
      if (text.startsWith(_initialData)) {
        final json = text.substring(_initialData.length).replaceFirst(RegExp(r';\s*$'), '');
        try {
          return jsonDecode(json);
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }

  /// The largest listed size is cropped to a square on multi-image posts;
  /// `=s0` asks the image server for the original.
  static ExtractedMediaDto? _image(JsonMap renderer) {
    final thumbnails = ExtractorHtml.at(renderer, ['image', 'thumbnails']);
    if (thumbnails is! List || thumbnails.isEmpty) {
      return null;
    }
    final url = ExtractorHtml.at(thumbnails.last, ['url']);
    if (url is! String) {
      return null;
    }
    final base = url.contains('=') ? url.substring(0, url.indexOf('=')) : url;
    return ExtractedMediaDto(url: '$base=s0', isVideo: false);
  }

  /// `{runs: [{text}]}` or `{simpleText}`.
  static String? _text(Object? node) {
    if (node case {'simpleText': final String text}) {
      return text;
    }
    final runs = ExtractorHtml.at(node, ['runs']);
    if (runs is! List) {
      return null;
    }
    final text = [
      for (final run in runs) ?ExtractorHtml.at(run, ['text']) as String?,
    ].join();
    return text.isEmpty ? null : text;
  }
}

import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/errors/extractor_errors.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/extracted_post_dto.dart';
import 'package:media_tool/data/services/remote/extractors/extractor_html.dart';
import 'package:media_tool/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_tool/data/services/remote/site_http_client.dart';
import 'package:media_tool/domain/models/site.dart';

/// Instagram photos and carousels from the post's public embed page, which
/// works without a login. See docs/extractors/photo_extractors.md#instagram.
@lazySingleton
final class InstagramPhotoExtractor({required final SiteHttpClient _http}) implements PhotoExtractor {
  static final _shortcode = RegExp('/(?:p|reels?|tv)/([A-Za-z0-9_-]+)');

  // The embed page carries the post as an escaped JSON string.
  static final _contextJson = RegExp(r'"contextJSON"\s*:\s*"((?:[^"\\]|\\.)*)"');
  static final _additionalData = RegExp(r"__additionalDataLoaded\(\s*'[^']*'\s*,\s*(\{.*?\})\s*\)\s*;", dotAll: true);

  @override
  Site get site => .instagram;

  @override
  bool canHandle(Uri url) => _shortcode.hasMatch(url.path);

  @override
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath}) async {
    final code = _shortcode.firstMatch(url.path)?.group(1);
    if (code == null) {
      throw ExtractorException(.noMedia, site: site, detail: 'no shortcode in ${url.path}');
    }
    final page = await _http.getText(
      Uri.https('www.instagram.com', '/p/$code/embed/captioned/'),
      site: cookiesPath == null ? null : site,
    );
    final document = ExtractorHtml.parse(page.body);

    final post = _postJson(page.body);
    final media = post == null ? <ExtractedMediaDto>[] : _mediaFromJson(post);
    if (media.isEmpty) {
      // Single photos: the embed's own <img>, widest srcset entry.
      final image = document.querySelector('img.EmbeddedMediaImage');
      final widest = ExtractorHtml.widestInSrcset(image?.attributes['srcset']);
      final src = widest?.url ?? image?.attributes['src'];
      if (src != null) {
        media.add(ExtractedMediaDto(url: src, isVideo: false, width: widest?.width));
      }
    }
    if (media.isEmpty) {
      // Private, removed or behind the login wall: Instagram cookies fix most.
      throw ExtractorException(.loginRequired, site: site, detail: 'embed page had no media');
    }

    final author =
        ExtractorHtml.at(post, ['owner', 'username']) as String? ??
        document.querySelector('.UsernameText')?.text.trim();
    final captionEdges = ExtractorHtml.at(post, ['edge_media_to_caption', 'edges']);
    final caption = captionEdges is List && captionEdges.isNotEmpty
        ? ExtractorHtml.at(captionEdges.first, ['node', 'text']) as String?
        : null;
    return ExtractedPostDto(postId: code, media: media, author: author, caption: caption);
  }

  /// The `shortcode_media` object from the embed page's scripts, if present.
  static JsonMap? _postJson(String body) {
    final candidates = <Object?>[
      for (final match in _contextJson.allMatches(body)) _decodeEscaped(match.group(1)!),
      for (final match in _additionalData.allMatches(body)) _decode(match.group(1)!),
    ];
    for (final candidate in candidates) {
      for (final object in ExtractorHtml.objects(candidate)) {
        if (object['shortcode_media'] case final JsonMap media) {
          return media;
        }
      }
    }
    return null;
  }

  /// Every slide in order; a single post is its own only slide.
  static List<ExtractedMediaDto> _mediaFromJson(JsonMap post) {
    final edges = ExtractorHtml.at(post, ['edge_sidecar_to_children', 'edges']);
    final nodes = edges is List && edges.isNotEmpty
        ? [
            for (final edge in edges) ?ExtractorHtml.at(edge, ['node']) as JsonMap?,
          ]
        : [post];
    return [for (final node in nodes) ?_slide(node)];
  }

  static ExtractedMediaDto? _slide(JsonMap node) {
    final width = ExtractorHtml.asInt(ExtractorHtml.at(node, ['dimensions', 'width']));
    final height = ExtractorHtml.asInt(ExtractorHtml.at(node, ['dimensions', 'height']));
    final display = node['display_url'] as String?;
    if (node['is_video'] == true) {
      final video = node['video_url'] as String?;
      return video == null
          ? null
          : ExtractedMediaDto(url: video, isVideo: true, width: width, height: height, thumbnailUrl: display);
    }
    // display_resources lists every size; take the widest.
    final resources = node['display_resources'];
    if (resources is List && resources.isNotEmpty) {
      final best = resources.whereType<JsonMap>().reduce(
        (a, b) =>
            (ExtractorHtml.asInt(a['config_width']) ?? 0) >= (ExtractorHtml.asInt(b['config_width']) ?? 0) ? a : b,
      );
      if (best['src'] case final String src) {
        return ExtractedMediaDto(
          url: src,
          isVideo: false,
          width: ExtractorHtml.asInt(best['config_width']) ?? width,
          height: ExtractorHtml.asInt(best['config_height']) ?? height,
        );
      }
    }
    return display == null ? null : ExtractedMediaDto(url: display, isVideo: false, width: width, height: height);
  }

  static Object? _decodeEscaped(String escaped) {
    final text = _decode('"$escaped"');
    return text is String ? _decode(text) : null;
  }

  static Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}

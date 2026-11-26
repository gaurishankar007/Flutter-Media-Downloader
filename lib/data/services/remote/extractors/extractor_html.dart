import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:media_downloader/core/types/types.dart';

/// HTML and embedded-JSON helpers shared by the photo extractors.
abstract final class ExtractorHtml {
  static Document parse(String body) => html.parse(body);

  /// `<meta property="og:image" content="…">` (or `name=`).
  static String? meta(Document document, String property) {
    final element =
        document.querySelector('meta[property="$property"]') ?? document.querySelector('meta[name="$property"]');
    final content = element?.attributes['content']?.trim();
    return content == null || content.isEmpty ? null : content;
  }

  /// The JSON in `<script id="[id]">`.
  static Object? scriptJson(Document document, String id) {
    final text = document.querySelector('script#$id')?.text;
    return text == null ? null : _tryDecode(text);
  }

  /// Every `<script type="application/json">` that parses.
  static List<Object> jsonScripts(Document document) => [
    for (final script in document.querySelectorAll('script[type="application/json"]')) ?_tryDecode(script.text),
  ];

  /// Every JSON object inside [node] (depth first, in document order).
  static Iterable<JsonMap> objects(Object? node) sync* {
    switch (node) {
      case final JsonMap map:
        yield map;
        for (final value in map.values) {
          yield* objects(value);
        }
      case final List<dynamic> list:
        for (final value in list) {
          yield* objects(value);
        }
    }
  }

  /// Follows [path] through nested maps.
  static Object? at(Object? node, List<String> path) {
    var current = node;
    for (final key in path) {
      if (current is! JsonMap) {
        return null;
      }
      current = current[key];
    }
    return current;
  }

  /// The widest `url 1080w` entry of a `srcset`.
  static ({String url, int? width})? widestInSrcset(String? srcset) {
    if (srcset == null || srcset.trim().isEmpty) {
      return null;
    }
    ({String url, int? width})? best;
    for (final candidate in srcset.split(',')) {
      final parts = candidate.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.isEmpty) {
        continue;
      }
      final width = parts.length > 1 ? int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '')) : null;
      if (best == null || (width ?? 0) > (best.width ?? 0)) {
        best = (url: parts.first, width: width);
      }
    }
    return best;
  }

  static int? asInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.round(),
    final String text => int.tryParse(text),
    _ => null,
  };

  static Object? _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}

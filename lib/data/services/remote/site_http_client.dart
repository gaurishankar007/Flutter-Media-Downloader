import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/local/cookies_local_service.dart';
import 'package:media_tool/domain/models/site.dart';

/// A fetched page and where it ended up after redirects.
typedef FetchedPage = ({Uri url, String body, int statusCode});

/// Every request of the photo extractors and direct downloads, with a normal
/// browser User-Agent and `Accept-Language: en`. Redirects are followed one hop
/// at a time so a site's imported cookies only ever go to that site's own
/// hosts. Nothing here logs headers or bodies. Methods throw (`DioException`);
/// callers run inside `ErrorHandler.execute`.
/// See docs/extractors/photo_extractors.md.
@lazySingleton
final class SiteHttpClient({required final CookiesLocalService _cookies}) {
  static const desktopUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/131.0.0.0 Safari/537.36';
  static const mobileUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/18.1 Mobile/15E148 Safari/604.1';
  static const _maxRedirects = 10;

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
      responseType: .plain,
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  /// Media files live on CDNs that never get cookies, so redirects can be
  /// followed automatically.
  final _downloadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 2),
      headers: {'User-Agent': desktopUserAgent, 'Accept-Language': 'en'},
    ),
  );

  /// GETs [url] as text. With [site], that site's cookies go along to its own
  /// hosts (and nowhere else).
  Future<FetchedPage> getText(
    Uri url, {
    Site? site,
    bool mobile = false,
    Map<String, String> headers = const {},
  }) async {
    var current = url;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final response = await _dio.getUri<String>(
        current,
        options: Options(
          headers: _headers(current, site: site, mobile: mobile, extra: headers),
        ),
      );
      final next = _redirectTarget(current, response);
      if (next == null) {
        return (url: current, body: response.data ?? '', statusCode: response.statusCode ?? 200);
      }
      current = next;
    }
    throw DioException(
      requestOptions: RequestOptions(path: '$url'),
      message: 'Too many redirects',
    );
  }

  /// GETs [url] and decodes it as a JSON object.
  Future<JsonMap?> getJson(Uri url, {Site? site, Map<String, String> headers = const {}}) async {
    final page = await getText(url, site: site, headers: headers);
    final decoded = page.body.trim().isEmpty ? null : jsonDecode(page.body);
    return decoded is JsonMap ? decoded : null;
  }

  /// Follows a short link's redirects (HEAD first, GET when HEAD isn't
  /// allowed) and returns where it lands.
  Future<Uri> resolveRedirects(Uri url, {Site? site}) async {
    var current = url;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final headers = _headers(current, site: site);
      Response<String> response;
      try {
        response = await _dio.headUri<String>(current, options: Options(headers: headers));
      } on DioException catch (error) {
        // Some short-link hosts answer HEAD with 404/405; GET works.
        if (error.type != .badResponse) {
          rethrow;
        }
        response = await _dio.getUri<String>(current, options: Options(headers: headers));
      }
      final next = _redirectTarget(current, response);
      if (next == null) {
        return current;
      }
      current = next;
    }
    return current;
  }

  /// Downloads [url] to [path], reporting bytes. No cookies are sent.
  Future<Headers> download(
    Uri url,
    String path, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Map<String, String> headers = const {},
  }) async {
    final response = await _downloadDio.downloadUri(
      url,
      path,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      options: Options(headers: headers),
    );
    return response.headers;
  }

  Map<String, String> _headers(Uri url, {Site? site, bool mobile = false, Map<String, String> extra = const {}}) => {
    'User-Agent': mobile ? mobileUserAgent : desktopUserAgent,
    'Accept-Language': 'en',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,application/json;q=0.8,*/*;q=0.7',
    // A browser's page-navigation headers: without them Facebook answers 400.
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
    ...extra,
    // Checked on every hop: the cookies service refuses hosts outside the site.
    'Cookie': ?(site == null ? null : _cookies.cookieHeader(site, url)),
  };

  static Uri? _redirectTarget(Uri from, Response<Object?> response) {
    final status = response.statusCode ?? 200;
    if (status < 300 || status >= 400) {
      return null;
    }
    final location = response.headers.value('location');
    return location == null ? null : from.resolve(location);
  }
}

import 'package:media_downloader/domain/models/site.dart';

/// Link helpers for pasted text. See docs/core/core_services.md#url-utils.
abstract final class UrlUtils {
  static final _urlPattern = RegExp(
    r'https?://[^\s<>"]+|(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)+/[^\s<>"]*',
    caseSensitive: false,
  );

  // Query params that only track the share, never identify the post.
  static const _trackingParams = {
    'igsh',
    'igshid',
    'fqnt',
    'si',
    'fbclid',
    'is_from_webapp',
    'sender_device',
    'feature',
    'ref',
    's',
    'mibextid',
  };

  /// The first URL in [text] ("Check this out https://…"), with https added if missing.
  static Uri? extractUrl(String text) {
    final match = _urlPattern.firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    final raw = match.group(0)!.replaceAll(RegExp(r'[).,!?]+$'), '');
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    return uri == null || uri.host.isEmpty ? null : uri;
  }

  /// Forces https and drops tracking params (`igsh`, `si`, `utm_*`, …).
  static Uri normalise(Uri url) {
    final query = {
      for (final MapEntry(:key, :value) in url.queryParameters.entries)
        if (!_trackingParams.contains(key) && !key.startsWith('utm_')) key: value,
    };
    // Built fresh: `Uri.replace(queryParameters: null)` would keep the old query.
    return Uri(
      scheme: 'https',
      userInfo: url.userInfo,
      host: url.host,
      port: url.hasPort ? url.port : null,
      path: url.path,
      queryParameters: query.isEmpty ? null : query,
      fragment: url.hasFragment ? url.fragment : null,
    );
  }

  // Hosts whose links only redirect to the real post.
  static const _shortHosts = {'vm.tiktok.com', 'vt.tiktok.com', 'fb.watch', 't.co', 'instagr.am'};

  /// A share link that has to be followed to find the post (`vm.tiktok.com`,
  /// `fb.watch`, `t.co`, Facebook `/share/…`).
  static bool isShortLink(Uri url) {
    final host = url.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (_shortHosts.contains(host)) {
      return true;
    }
    final isFacebook = host == 'facebook.com' || host.endsWith('.facebook.com');
    return isFacebook && url.path.startsWith('/share/');
  }

  /// A link that can only be a photo post: TikTok `/photo/`, Facebook
  /// `/photo`, `/photos/`, `photo.php`. Instagram `/p/` can be either, so
  /// it's decided by trying.
  static bool looksLikePhotoPost(Uri url) {
    final path = url.path.toLowerCase();
    return switch (detectSite(url)) {
      .tiktok => path.contains('/photo/'),
      .facebook => path.startsWith('/photo') || path.contains('/photos/') || path.contains('photo.php'),
      _ => false,
    };
  }

  /// The supported site [url] belongs to, or `null`.
  static Site? detectSite(Uri url) {
    final host = url.host.toLowerCase();
    for (final site in Site.values) {
      if (site.domains.any((domain) => host == domain || host.endsWith('.$domain'))) {
        return site;
      }
    }
    return null;
  }
}

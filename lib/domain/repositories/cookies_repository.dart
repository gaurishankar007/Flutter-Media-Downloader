import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/cookie_browser.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/models/site_cookies.dart';

/// Imported cookies per site. They stay on the device and only go to their
/// own site. See docs/features/settings.md#cookies.
abstract interface class CookiesRepository {
  /// The browsers yt-dlp can read cookies from here (desktops); empty on phones.
  List<CookieBrowser> get cookieBrowsers;

  /// The sites that have cookies.
  FutureList<SiteCookies> list();

  /// Lets the user pick a cookies.txt and stores [site]'s cookies from it.
  /// `null` when the picker was cancelled.
  FutureData<SiteCookies?> import(Site site);

  FutureVoid remove(Site site);
}

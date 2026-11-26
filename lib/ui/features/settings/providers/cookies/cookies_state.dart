part of 'cookies_notifier.dart';

final class const CookiesState({
  final List<SiteCookies> cookies = const [],

  /// The site whose import is running.
  final Site? busySite,
  final bool supportsBrowserCookies = false,
  super.status,
  super.message,
}) extends BaseState {
  SiteCookies? cookiesFor(Site site) => cookies.where((entry) => entry.site == site).firstOrNull;

  CookiesState copyWith({
    List<SiteCookies>? cookies,
    Site? busySite,
    bool clearBusySite = false,
    StateStatus? status,
    StateMessage? message,
  }) => CookiesState(
    cookies: cookies ?? this.cookies,
    busySite: clearBusySite ? null : busySite ?? this.busySite,
    supportsBrowserCookies: supportsBrowserCookies,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [cookies, busySite, supportsBrowserCookies, ...super.props];
}

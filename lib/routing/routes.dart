import 'package:auto_route/auto_route.dart';
import 'package:media_tool/routing/routes.gr.dart';

/// Route tree. See docs/core/routing.md.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const .adaptive();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeShellRoute.page,
      path: '/',
      initial: true,
      children: [
        AutoRoute(page: DownloadRoute.page, path: 'download', initial: true),
        AutoRoute(page: LibraryRoute.page, path: 'library'),
        AutoRoute(page: ToolsRoute.page, path: 'tools'),
        AutoRoute(page: SystemRoute.page, path: 'system'),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
      ],
    ),
    // Library viewer: full screen above the tabs.
    AutoRoute(page: MediaViewerRoute.page, path: '/viewer'),
    // A grouped post (or a tool's several outputs): details and every item.
    AutoRoute(page: LibraryPostRoute.page, path: '/library/post'),
    // Tools: the converter and each tool, full screen above the tabs.
    AutoRoute(page: ConvertRoute.page, path: '/tools/convert'),
    AutoRoute(page: ToolRoute.page, path: '/tools/tool'),
    // Settings sub-pages, full screen above the tabs.
    AutoRoute(page: CookiesRoute.page, path: '/settings/cookies'),
    AutoRoute(page: AboutRoute.page, path: '/settings/about'),
    // Debug builds only; the Settings entry is hidden in release.
    AutoRoute(page: DesignGalleryRoute.page, path: '/design-gallery'),
  ];
}

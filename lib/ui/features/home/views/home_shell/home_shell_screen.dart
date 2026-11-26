import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/providers/screen_type/screen_type_notifier.dart';
import 'package:media_tool/ui/core/themes/app_motion.dart';
import 'package:media_tool/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_tool/ui/features/download/providers/engine_status/engine_status_notifier.dart';
import 'package:media_tool/ui/features/home/models/nav_destination.dart';
import 'package:media_tool/ui/features/home/views/home_shell/widgets/app_navigation_bar.dart';
import 'package:media_tool/ui/features/home/views/home_shell/widgets/app_sidebar.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';
import 'package:media_tool/ui/startup/rights_notice_dialog.dart';

/// The tab shell: floating bottom bar on phones/tablets, sidebar on wide screens.
@RoutePage()
class const HomeShellScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRightsNoticeOnce());
  }

  Future<void> _showRightsNoticeOnce() async {
    if (ref.read(settingsProvider).settings.rightsNoticeAccepted || !mounted) {
      return;
    }
    await showRightsNoticeDialog(context);
    await ref.read(settingsProvider.notifier).acceptRightsNotice();
  }

  @override
  Widget build(BuildContext context) {
    // Shown here, not per screen, so a change from any tab gets one toast.
    ref
      ..listenMessages(settingsProvider, context)
      ..listenMessages(engineStatusProvider, context);
    final usesSidebar = ref.watch(screenTypeProvider.select((type) => type.usesSidebar));
    final badges = {
      if (ref.watch(engineStatusProvider.select((state) => state.updateAvailable))) NavDestination.settings,
    };
    return AutoTabsRouter(
      routes: const [DownloadRoute(), LibraryRoute(), ConvertRoute(), SystemRoute(), SettingsRoute()],
      duration: AppMotion.normal,
      transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        if (usesSidebar) {
          return Scaffold(
            body: Row(
              children: [
                AppSidebar(
                  selectedIndex: tabsRouter.activeIndex,
                  onSelected: tabsRouter.setActiveIndex,
                  badges: badges,
                ),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: AppNavigationBar(
            selectedIndex: tabsRouter.activeIndex,
            onSelected: tabsRouter.setActiveIndex,
            badges: badges,
          ),
        );
      },
    );
  }
}

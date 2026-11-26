import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/routing/routes.gr.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_downloader/ui/core/ui/base/states/empty_state.dart';
import 'package:media_downloader/ui/core/ui/base/states/shimmer_box.dart';
import 'package:media_downloader/ui/features/system/models/monitor_visibility.dart';
import 'package:media_downloader/ui/features/system/providers/system_monitor/system_monitor_notifier.dart';
import 'package:media_downloader/ui/features/system/views/system/widgets/metric_cards_grid.dart';
import 'package:media_downloader/ui/features/system/views/system/widgets/system_metric_card.dart';

/// The System tab: live device stats, one card per supported metric with the
/// last minute as a sparkline. Polls only while this tab is on screen and the
/// app is visible.
@RoutePage()
class const SystemScreen({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onScreen =
        isAppVisible(useAppLifecycleState()) &&
        context.watchTabsRouter.current.name == SystemRoute.name &&
        (ModalRoute.isCurrentOf(context) ?? true);
    // Tabs stay mounted; not watching lets the autoDispose notifier stop polling.
    final state = onScreen ? ref.watch(systemMonitorProvider) : const SystemMonitorState();

    return ScreenScrollView(
      children: [
        const ScreenHeader(title: SystemMessages.title, subtitle: SystemMessages.subtitle),
        if (!state.metricsKnown)
          const MetricCardsGrid(
            children: [
              ShimmerBox(height: 200, borderRadius: AppRadius.lgAll),
              ShimmerBox(height: 200, borderRadius: AppRadius.lgAll),
            ],
          )
        else if (state.metrics.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Symbols.monitoring_rounded,
              title: SystemMessages.unavailableTitle,
              body: SystemMessages.unavailableBody,
            ),
          )
        else
          MetricCardsGrid(
            children: [
              for (final metric in state.metrics)
                SystemMetricCard(metric: metric, latest: state.latest, history: state.history),
            ],
          ),
      ],
    );
  }
}

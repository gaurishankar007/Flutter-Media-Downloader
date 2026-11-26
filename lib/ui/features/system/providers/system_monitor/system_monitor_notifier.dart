import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/domain/models/system_metric.dart';
import 'package:media_downloader/domain/models/system_sample.dart';
import 'package:media_downloader/domain/repositories/system_monitor_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';

part 'system_monitor_state.dart';

/// Polls the device stats once a second while the System tab watches it;
/// autoDispose stops the timer as soon as the tab is off screen. Failures stay in the error log
/// only: a background monitor never toasts.
class SystemMonitorNotifier extends BaseNotifier<SystemMonitorState> {
  static const interval = Duration(seconds: 1);

  /// Sparkline window: 60 readings, one a second.
  static const historyLength = 60;

  /// Consecutive failed readings after which polling stops.
  static const _maxFailures = 3;

  late final SystemMonitorRepository _repository;
  Timer? _timer;
  bool _sampling = false;
  int _failures = 0;

  @override
  SystemMonitorState build() {
    _repository = GetIt.I<SystemMonitorRepository>();
    ref.onDispose(() => _timer?.cancel());
    final known = _repository.knownMetrics;
    // Cached after the first time, so returning to the tab keeps its layout.
    Future.microtask(_loadMetrics);
    return SystemMonitorState(metrics: known ?? const [], metricsKnown: known != null);
  }

  Future<void> _loadMetrics() => runFlow('systemMonitor.metrics', () async {
    final result = await _repository.metrics();
    if (!ref.mounted) {
      return;
    }
    final metrics = switch (result) {
      SuccessState(:final data?) => data,
      _ => const <SystemMetric>[],
    };
    state = state.copyWith(metrics: metrics, metricsKnown: true);
    _start();
  });

  void _start() {
    if (!ref.mounted || state.metrics.isEmpty) {
      return;
    }
    _sample();
    _timer = Timer.periodic(interval, (_) => _sample());
  }

  Future<void> _sample() => runFlow('systemMonitor.sample', () async {
    if (_sampling) {
      return;
    }
    _sampling = true;
    final result = await _repository.sample();
    _sampling = false;
    if (!ref.mounted) {
      return;
    }
    if (result case SuccessState(:final data?)) {
      _failures = 0;
      final history = [...state.history, data];
      state = state.copyWith(
        latest: data,
        history: history.length > historyLength ? history.sublist(history.length - historyLength) : history,
      );
    } else if (++_failures >= _maxFailures) {
      _timer?.cancel();
    }
  });
}

final systemMonitorProvider = NotifierProvider.autoDispose(SystemMonitorNotifier.new);

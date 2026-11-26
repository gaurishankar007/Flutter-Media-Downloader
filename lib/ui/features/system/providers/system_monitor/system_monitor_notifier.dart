import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';
import 'package:media_tool/domain/repositories/system_monitor_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';

part 'system_monitor_state.dart';

/// Polls the device stats once a second while the System tab watches it;
/// autoDispose stops the timer as soon as the tab is off screen. Storage and
/// battery change slowly, so they're read every [slowEvery] ticks, and the
/// app's own folder (a walk over every file) on open and every [appFilesEvery]
/// ticks. Failures stay in the error log only: a background monitor never toasts.
class SystemMonitorNotifier extends BaseNotifier<SystemMonitorState> {
  static const interval = Duration(seconds: 1);

  /// Storage and battery: every 5 s.
  static const slowEvery = 5;

  /// The app's own folder size: every 30 s.
  static const appFilesEvery = 30;

  /// Sparkline window: 60 readings, one a second.
  static const historyLength = 60;

  /// Consecutive failed readings after which polling stops.
  static const _maxFailures = 3;

  late final SystemMonitorRepository _repository;
  Timer? _timer;
  bool _sampling = false;
  bool _slowSampling = false;
  int _failures = 0;
  int _ticks = 0;

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
    _sampleSlow(measureAppFiles: true);
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void _tick() {
    _sample();
    _ticks++;
    if (_ticks % slowEvery == 0) {
      _sampleSlow(measureAppFiles: _ticks % appFilesEvery == 0);
    }
  }

  /// Storage and battery, for the metrics this device has. A failed reading
  /// keeps the last values.
  Future<void> _sampleSlow({required bool measureAppFiles}) => runFlow('systemMonitor.storageBattery', () async {
    if (_slowSampling) {
      return;
    }
    _slowSampling = true;
    final metrics = state.metrics;
    final storage = metrics.contains(SystemMetric.storage)
        ? await _repository.storage(measureAppFiles: measureAppFiles)
        : null;
    final battery = metrics.contains(SystemMetric.battery) ? await _repository.battery() : null;
    _slowSampling = false;
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      storage: switch (storage) {
        SuccessState(:final data?) => data,
        _ => null,
      },
      battery: switch (battery) {
        SuccessState(:final data?) => data,
        _ => null,
      },
    );
  });

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

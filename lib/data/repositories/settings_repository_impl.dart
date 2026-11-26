import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/local/settings_local_service.dart';
import 'package:media_tool/domain/models/app_settings.dart';
import 'package:media_tool/domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
final class SettingsRepositoryImpl({required final SettingsLocalService _localService}) implements SettingsRepository {
  final _changes = StreamController<AppSettings>.broadcast();
  AppSettings _current = const AppSettings();

  @override
  AppSettings get current => _current;

  @override
  FutureData<AppSettings> load() async {
    final result = await _localService.readSettings();
    return switch (result) {
      SuccessState(:final data) => SuccessState(data: _current = data == null ? const AppSettings() : .fromJson(data)),
      final FailureState<JsonMap?> failure => failure.retype(),
      LoadingState() => const LoadingState(),
    };
  }

  @override
  Stream<AppSettings> watch() => _changes.stream;

  @override
  FutureData<AppSettings> update(AppSettings Function(AppSettings settings) change) async {
    final next = change(_current);
    final result = await _localService.writeSettings(next.toJson());
    return switch (result) {
      SuccessState() => SuccessState(data: _publish(next)),
      final FailureState<void> failure => failure.retype(),
      LoadingState() => const LoadingState(),
    };
  }

  AppSettings _publish(AppSettings settings) {
    _current = settings;
    _changes.add(settings);
    return settings;
  }
}

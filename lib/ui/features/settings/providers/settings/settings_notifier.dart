import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/domain/models/app_settings.dart';
import 'package:media_tool/domain/models/app_theme_mode.dart';
import 'package:media_tool/domain/models/audio_quality.dart';
import 'package:media_tool/domain/models/cookie_browser.dart';
import 'package:media_tool/domain/models/video_quality.dart';
import 'package:media_tool/domain/repositories/settings_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';

part 'settings_state.dart';

/// App settings. Keep-alive: the whole app reads it, and every write goes
/// through here so Settings always shows the stored values.
/// See docs/features/settings.md.
class SettingsNotifier extends BaseNotifier<SettingsState> {
  late final SettingsRepository _repository;

  @override
  SettingsState build() {
    _repository = GetIt.I<SettingsRepository>();
    final subscription = _repository.watch().listen(_onChanged);
    ref.onDispose(subscription.cancel);
    return SettingsState(settings: _repository.current, status: .loaded);
  }

  Future<void> setThemeMode(AppThemeMode themeMode) =>
      runFlow('settings.setThemeMode', () => update((settings) => settings.copyWith(themeMode: themeMode)));

  Future<void> acceptRightsNotice() =>
      runFlow('settings.acceptRightsNotice', () => update((settings) => settings.copyWith(rightsNoticeAccepted: true)));

  Future<void> setDefaultVideoQuality(VideoQuality quality) => runFlow(
    'settings.setDefaultVideoQuality',
    () => update((settings) => settings.copyWith(defaultVideoQuality: quality)),
  );

  Future<void> setDefaultAudioQuality(AudioQuality quality) => runFlow(
    'settings.setDefaultAudioQuality',
    () => update((settings) => settings.copyWith(defaultAudioQuality: quality)),
  );

  Future<void> setIphoneCompatible(bool value) =>
      runFlow('settings.setIphoneCompatible', () => update((settings) => settings.copyWith(iphoneCompatible: value)));

  Future<void> setPhotosToJpg(bool value) =>
      runFlow('settings.setPhotosToJpg', () => update((settings) => settings.copyWith(photosToJpg: value)));

  Future<void> setAskRemoveAfterSave(bool value) => runFlow(
    'settings.setAskRemoveAfterSave',
    () => update((settings) => settings.copyWith(askRemoveAfterSave: value)),
  );

  Future<void> setCookieBrowser(CookieBrowser browser) =>
      runFlow('settings.setCookieBrowser', () => update((settings) => settings.copyWith(cookieBrowser: browser)));

  Future<void> setCheckEngineOnLaunch(bool value) => runFlow(
    'settings.setCheckEngineOnLaunch',
    () => update((settings) => settings.copyWith(checkEngineOnLaunch: value)),
  );

  /// Records the launch update check, so the next one waits a day.
  Future<void> markEngineChecked() => runFlow(
    'settings.markEngineChecked',
    () => update((settings) => settings.copyWith(lastEngineCheckAt: DateTime.now())),
  );

  /// Applies [change] and stores it. Call inside a `runFlow`.
  Future<void> update(AppSettings Function(AppSettings settings) change) async {
    final result = await _repository.update(change);
    if (!ref.mounted) {
      return;
    }
    state = switch (result) {
      SuccessState(:final data) => state.copyWith(settings: data),
      FailureState() => state.copyWith(message: trackFailure(result)),
      LoadingState() => state.copyWith(),
    };
  }

  void _onChanged(AppSettings settings) {
    if (ref.mounted && settings != state.settings) {
      state = state.copyWith(settings: settings);
    }
  }
}

final settingsProvider = NotifierProvider(SettingsNotifier.new);

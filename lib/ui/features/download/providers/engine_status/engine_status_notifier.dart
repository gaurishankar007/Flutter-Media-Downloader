import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/engine_info.dart';
import 'package:media_tool/domain/repositories/media_repository.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';

part 'engine_status_state.dart';

/// Starts the download engine once, when first watched (after the first
/// frame), says whether it's ready, and checks for / installs yt-dlp
/// updates. Keep-alive. See
/// docs/architecture/app_startup.md#engine-init-runs-after-the-first-frame
/// and docs/features/settings.md#engine.
class EngineStatusNotifier extends BaseNotifier<EngineStatusState> {
  static const _checkInterval = Duration(days: 1);

  late final MediaRepository _repository;
  SettingsNotifier? _settings;

  @override
  EngineStatusState build() {
    _repository = GetIt.I<MediaRepository>();
    _settings = ref.read(settingsProvider.notifier);
    Future.microtask(_init);
    return const EngineStatusState();
  }

  Future<void> retry() async {
    if (state.engineStatus == .failed) {
      state = const EngineStatusState();
      await _init();
    }
  }

  /// Looks for a newer yt-dlp. [silent] (the launch check) shows nothing
  /// when the check fails or finds nothing.
  Future<void> checkForUpdate({bool silent = false}) => runFlow('engine.checkForUpdate', () async {
    if (state.engineStatus != .ready || state.updateStatus != .idle) {
      return;
    }
    state = state.copyWith(updateStatus: .checking);
    final result = await _repository.checkForUpdate();
    state = switch (result) {
      SuccessState(:final data?) when data.available => state.copyWith(
        updateStatus: .idle,
        availableVersion: data.latestVersion,
      ),
      SuccessState() => state.copyWith(
        updateStatus: .idle,
        clearAvailableVersion: true,
        message: silent ? null : const NormalMessage(EngineMessages.upToDate),
      ),
      _ => state.copyWith(updateStatus: .idle, message: silent ? null : trackFailure(result)),
    };
  });

  /// Updates yt-dlp now.
  Future<void> update() => runFlow('engine.update', () async {
    if (state.engineStatus != .ready || state.updateStatus != .idle) {
      return;
    }
    final before = state.info?.ytDlpVersion;
    state = state.copyWith(updateStatus: .updating);
    final result = await _repository.updateEngine();
    state = switch (result) {
      SuccessState(:final data?) => state.copyWith(
        updateStatus: .idle,
        info: EngineInfo(ytDlpVersion: data, encoders: state.info?.encoders ?? const []),
        clearAvailableVersion: true,
        message: data == before
            ? const NormalMessage(EngineMessages.upToDate)
            : SuccessMessage(EngineMessages.updated(data)),
      ),
      _ => state.copyWith(updateStatus: .idle, message: trackFailure(result)),
    };
  });

  Future<void> _init() => runFlow('engine.init', () async {
    final result = await _repository.initEngine();
    state = switch (result) {
      SuccessState(:final data) => EngineStatusState(engineStatus: .ready, info: data),
      // Shown in place (preview sheet), not as a toast.
      _ => EngineStatusState(engineStatus: .failed, errorText: trackFailure(result).text),
    };
    if (state.engineStatus == .ready) {
      await _checkOnLaunch();
    }
  });

  /// At most once a day, when the user hasn't turned it off. Never updates by itself.
  Future<void> _checkOnLaunch() async {
    final settings = ref.read(settingsProvider).settings;
    final lastCheck = settings.lastEngineCheckAt;
    if (!settings.checkEngineOnLaunch || (lastCheck != null && DateTime.now().difference(lastCheck) < _checkInterval)) {
      return;
    }
    await checkForUpdate(silent: true);
    await _settings?.markEngineChecked();
  }
}

final engineStatusProvider = NotifierProvider(EngineStatusNotifier.new);

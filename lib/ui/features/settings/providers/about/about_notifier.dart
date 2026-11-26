import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/repositories/app_info_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';

part 'about_state.dart';

/// Settings → About: the app version and copying the error log.
class AboutNotifier extends BaseNotifier<AboutState> {
  late final AppInfoRepository _repository;

  @override
  AboutState build() {
    _repository = GetIt.I<AppInfoRepository>();
    Future.microtask(_loadVersion);
    return const AboutState();
  }

  Future<void> copyErrorLog() => runFlow('about.copyErrorLog', () async {
    final result = await _repository.copyErrorLog();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      message: switch (result) {
        SuccessState(data: 0 || null) => const NormalMessage(AboutMessages.errorLogEmpty),
        SuccessState(:final data?) => SuccessMessage(AboutMessages.copied(data)),
        _ => trackFailure(result),
      },
    );
  });

  Future<void> _loadVersion() => runFlow('about.version', () async {
    final result = await _repository.appVersion();
    if (result case SuccessState(:final data?) when ref.mounted) {
      state = state.copyWith(appVersion: data);
    }
  });
}

final aboutProvider = NotifierProvider.autoDispose(AboutNotifier.new);

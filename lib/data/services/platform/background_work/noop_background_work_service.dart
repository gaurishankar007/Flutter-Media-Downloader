import 'package:injectable/injectable.dart';
import 'package:media_downloader/config/injector/platform_env.dart';
import 'package:media_downloader/data/services/platform/background_work/background_work_service.dart';
import 'package:media_downloader/domain/models/background_activity.dart';

/// iOS and macOS: macOS keeps running in the background anyway; iOS
/// background time is handled with the iOS engine (build-order step 5).
@LazySingleton(as: BackgroundWorkService, env: [PlatformEnv.ios, PlatformEnv.macos])
final class NoopBackgroundWorkService implements BackgroundWorkService {
  @override
  Stream<String> get cancelRequests => const Stream.empty();

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> show(BackgroundActivity activity) async {}

  @override
  Future<void> stop() async {}
}

import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:media_downloader/config/injector/platform_env.dart';
import 'package:media_downloader/core/clients/platform/background_work_api.g.dart';
import 'package:media_downloader/data/services/platform/background_work/background_work_service.dart';
import 'package:media_downloader/domain/models/background_activity.dart';
import 'package:permission_handler/permission_handler.dart';

/// `DownloadService` (a `dataSync` foreground service) through Pigeon
/// (Kotlin: `background/`).
@LazySingleton(as: BackgroundWorkService, env: [PlatformEnv.android])
final class AndroidBackgroundWorkService implements BackgroundWorkService, BackgroundWorkFlutterApi {
  new() {
    BackgroundWorkFlutterApi.setUp(this);
  }

  final _api = BackgroundWorkHostApi();
  final _cancelRequests = StreamController<String>.broadcast();

  @override
  Stream<String> get cancelRequests => _cancelRequests.stream;

  @override
  void cancelRequested(String jobId) => _cancelRequests.add(jobId);

  @override
  Future<void> requestNotificationPermission() async {
    // Denied is fine: downloads still run, only the notification is hidden.
    await Permission.notification.request();
  }

  @override
  Future<void> show(BackgroundActivity activity) => _api.update(
    BackgroundWorkMsg(
      jobId: activity.jobId,
      title: activity.title,
      percent: activity.percent,
      activeCount: activity.activeCount,
    ),
  );

  @override
  Future<void> stop() => _api.stop();
}

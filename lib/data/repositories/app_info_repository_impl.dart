import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/error_handler.dart';
import 'package:media_downloader/core/services/clipboard_service.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/data/services/local/error_log_local_service.dart';
import 'package:media_downloader/data/services/platform/app_info_service.dart';
import 'package:media_downloader/domain/repositories/app_info_repository.dart';

@LazySingleton(as: AppInfoRepository)
final class AppInfoRepositoryImpl({
  required final AppInfoService _appInfo,
  required final ErrorLogLocalService _errorLog,
  required final ClipboardService _clipboard,
  required final ErrorHandler _errorHandler,
}) implements AppInfoRepository {
  @override
  FutureData<String> appVersion() => _errorHandler.execute(action: 'about.version', () async {
    return SuccessState(data: await _appInfo.version());
  });

  @override
  FutureData<int> copyErrorLog() => _errorHandler.execute(action: 'about.copyErrorLog', () async {
    final lines = await _errorLog.readLines();
    if (lines case final FailureState<List<String>> failure) {
      return failure.retype();
    }
    final entries = lines.data ?? const <String>[];
    await _clipboard.writeText(entries.join('\n'));
    return SuccessState(data: entries.length);
  });
}

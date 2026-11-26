import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/error_handler.dart';
import 'package:media_downloader/core/types/types.dart';

/// Asks GitHub for the latest stable yt-dlp release. An anonymous request
/// that sends nothing about the user. See docs/engine/media_engine.md#updates.
abstract interface class EngineReleaseService {
  /// The latest release tag, e.g. `2026.11.23`.
  FutureData<String> latestYtDlpVersion();
}

@LazySingleton(as: EngineReleaseService)
final class EngineReleaseServiceImpl({required final ErrorHandler _errorHandler}) implements EngineReleaseService {
  static const _latestRelease = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/vnd.github+json'},
    ),
  );

  @override
  FutureData<String> latestYtDlpVersion() => _errorHandler.execute(action: 'engine.latestVersion', () async {
    final response = await _dio.get<JsonMap>(_latestRelease);
    final tag = response.data?['tag_name'] as String?;
    return tag == null ? const FailureState() : SuccessState(data: tag);
  });
}

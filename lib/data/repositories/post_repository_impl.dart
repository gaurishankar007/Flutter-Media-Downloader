import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/mappers/post_mapper.dart';
import 'package:media_tool/data/services/local/cookies_local_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/remote/extractors/photo_extractors.dart';
import 'package:media_tool/data/services/remote/media_file_downloader.dart';
import 'package:media_tool/data/services/remote/site_http_client.dart';
import 'package:media_tool/domain/models/download_event.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/repositories/post_repository.dart';
import 'package:path/path.dart' as p;

@LazySingleton(as: PostRepository)
final class PostRepositoryImpl({
  required final PhotoExtractors _extractors,
  required final SiteHttpClient _http,
  required final MediaFileDownloader _downloader,
  required final ImageService _images,
  required final CookiesLocalService _cookies,
  required final AppDirectories _directories,
  required final ErrorHandler _errorHandler,
}) implements PostRepository {
  static const _progressInterval = Duration(milliseconds: 250);
  static const _jpgExtensions = {'.jpg', '.jpeg'};
  static const _videoExtensions = {'.mp4', '.mov', '.webm', '.m4v'};

  @override
  bool supports(Site site) => _extractors.supports(site);

  @override
  FutureData<Uri> followShortLink(Uri url) => _errorHandler.execute(action: 'post.followShortLink', () async {
    return SuccessState(data: await _http.resolveRedirects(url));
  });

  @override
  FutureData<MediaInfo> extract(Uri url, Site site) =>
      _errorHandler.execute(action: 'extractor.${site.name}', () async {
        final extractor = _extractors.forUrl(url, site);
        if (extractor == null) {
          return const FailureState(message: EngineMessages.unsupported);
        }
        final dto = await extractor.extract(url, cookiesPath: _cookies.pathFor(site));
        return SuccessState(
          data: PostMapper.fromDto(dto, url: '$url', site: site),
        );
      });

  @override
  Stream<DownloadEvent> download(DownloadJob job) {
    final controller = StreamController<DownloadEvent>();
    controller.onListen = () async {
      final result = await _errorHandler.execute(action: 'post.download', () => _downloadAll(job, controller.add));
      controller.add(switch (result) {
        _ when _downloader.isCancelled(job.id) => const DownloadCancelled(),
        SuccessState(:final data?) => data,
        SuccessState() => const DownloadCancelled(),
        _ => DownloadFailed(result.message ?? ExtractorMessages.downloadFailed),
      });
      _downloader.release(job.id);
      await controller.close();
    };
    return controller.stream;
  }

  @override
  FutureList<String> convertPhotosToJpg(List<String> paths) =>
      _errorHandler.execute(action: 'post.convertPhotos', () async {
        final converted = <String>[];
        for (final path in paths) {
          final extension = p.extension(path).toLowerCase();
          if (_jpgExtensions.contains(extension) || _videoExtensions.contains(extension)) {
            converted.add(path);
            continue;
          }
          final output = p.setExtension(path, '.jpg');
          await _images.toJpg(path, output);
          converted.add(output);
        }
        return SuccessState(data: converted);
      });

  @override
  Future<void> cancel(String jobId) async => _downloader.cancel(jobId);

  /// Downloads every chosen item in order, reporting progress across all of
  /// them. `SuccessState(data: null)` means it was cancelled.
  FutureData<PostDownloadFinished?> _downloadAll(DownloadJob job, void Function(DownloadEvent) emit) async {
    final request = job.request;
    final directory = _directories.workFor(job.id);
    final headers = {'Referer': 'https://www.${request.site.domains.first}/'};
    final total = request.media.length;
    final stopwatch = Stopwatch()..start();
    var lastEmit = Duration.zero;
    var bytesBefore = 0;

    void report(int index, int received, int size) {
      final now = stopwatch.elapsed;
      if (now - lastEmit < _progressInterval) {
        return;
      }
      lastEmit = now;
      final fileFraction = size > 0 ? received / size : 0.0;
      final seconds = now.inMilliseconds / 1000;
      emit(
        DownloadProgressed(
          JobProgress(
            stage: .downloading,
            fraction: ((index + fileFraction) / total).clamp(0.0, 1.0),
            speedBytesPerSecond: seconds > 0 ? (bytesBefore + received) / seconds : null,
          ),
        ),
      );
    }

    emit(const DownloadProgressed(JobProgress(stage: .downloading, fraction: 0)));
    final paths = <String>[];
    final thumbnails = <String?>[];
    try {
      for (final (index, item) in request.media.indexed) {
        final stem = (index + 1).toString().padLeft(2, '0');
        var size = 0;
        final path = await _downloader.download(
          job.id,
          Uri.parse(item.url),
          directory: directory,
          stem: stem,
          fallbackExtension: item.kind == .video ? 'mp4' : 'jpg',
          headers: headers,
          onProgress: (received, fileSize) {
            size = received;
            report(index, received, fileSize);
          },
        );
        bytesBefore += size;
        paths.add(path);
        thumbnails.add(item.kind == .video ? await _still(job.id, item.thumbnailUrl, directory, stem) : null);
      }

      String? music;
      if (request.slideshowVideo && request.musicUrl != null) {
        music = await _downloader.download(
          job.id,
          Uri.parse(request.musicUrl!),
          directory: directory,
          stem: 'music',
          fallbackExtension: 'mp3',
          headers: headers,
        );
      }
      return SuccessState(
        data: PostDownloadFinished(paths: paths, thumbnailPaths: thumbnails, musicPath: music),
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return const SuccessState(data: null);
      }
      rethrow;
    }
  }

  /// A video's still for its Library thumbnail. Best-effort.
  Future<String?> _still(String jobId, String? url, String directory, String stem) async {
    if (url == null) {
      return null;
    }
    return await _errorHandler.executeSafeReturn(
      () => _downloader.download(
        jobId,
        Uri.parse(url),
        directory: directory,
        stem: 'still_$stem',
        fallbackExtension: 'jpg',
      ),
      onError: (_) => null,
    );
  }
}

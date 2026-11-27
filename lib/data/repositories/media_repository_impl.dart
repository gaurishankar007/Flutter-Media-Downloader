import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/engine_errors.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/mappers/media_info_mapper.dart';
import 'package:media_tool/data/services/local/cookies_local_service.dart';
import 'package:media_tool/data/services/platform/media_engine/builders/ffmpeg_command_builder.dart';
import 'package:media_tool/data/services/platform/media_engine/builders/yt_dlp_args_builder.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/ffmpeg_slot.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/data/services/platform/media_engine/parsers/download_progress_parser.dart';
import 'package:media_tool/data/services/remote/engine_release_service.dart';
import 'package:media_tool/domain/models/cookie_browser.dart';
import 'package:media_tool/domain/models/download_event.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/engine_info.dart';
import 'package:media_tool/domain/models/engine_update.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/repositories/media_repository.dart';
import 'package:media_tool/domain/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;

@LazySingleton(as: MediaRepository)
final class MediaRepositoryImpl({
  required final MediaEngine _engine,
  required final AppDirectories _directories,
  required final FileService _files,
  required final CookiesLocalService _cookies,
  required final SettingsRepository _settings,
  required final EngineReleaseService _releases,
  required final FfmpegSlot _slot,
}) implements MediaRepository {
  EngineInfo? _info;

  @override
  FutureData<EngineInfo> initEngine() async {
    final result = await _engine.init();
    if (result case SuccessState(:final data?)) {
      _info = data;
    }
    return result;
  }

  @override
  FutureData<MediaInfo> probe(String url, Site site) async {
    final cookies = _cookiesFor(site);
    final result = await _engine.probe(
      YtDlpArgsBuilder.probe(url, cookiesPath: cookies.path, browser: cookies.browser),
    );
    return switch (result) {
      SuccessState(:final data?) => SuccessState(
        data: MediaInfoMapper.fromDto(data, url: url, site: site),
      ),
      final FailureState<Object?> failure => failure.retype(),
      _ => const FailureState(),
    };
  }

  @override
  Stream<DownloadEvent> download(DownloadJob job) async* {
    final workDir = _directories.workFor(job.id);
    final request = job.request;
    final parser = DownloadProgressParser(
      expectedBytes: request.expectedBytes,
      durationSeconds: request.durationSeconds,
    );
    final cookies = _cookiesFor(request.site);
    final args = YtDlpArgsBuilder.download(
      request,
      workDir: workDir,
      cookiesPath: cookies.path,
      browser: cookies.browser,
    );

    await for (final event in _engine.download(job.id, args)) {
      switch (event) {
        case EngineLine(:final text):
          if (parser.parseYtDlp(text) case final progress?) {
            yield DownloadProgressed(progress);
          }
        case EngineDone():
          yield await _finished(workDir);
        case EngineFailed(:final output):
          yield DownloadFailed(EngineErrors.messageFor(output));
        case EngineCancelled():
          yield const DownloadCancelled();
      }
    }
  }

  @override
  Stream<DownloadEvent> convertForIphone(DownloadJob job, String inputPath) async* {
    final output = p.join(_directories.workFor(job.id), 'iphone.mp4');
    final parser = DownloadProgressParser(durationSeconds: job.request.durationSeconds);
    final encoders = FfmpegCommandBuilder.iphoneEncoders(_info?.encoders ?? const []);
    // Hardware encoders fail on some phones; each one is a fallback for the one before.
    yield* _runFfmpeg(
      job.id,
      step: .convertingForIphone,
      commands: [
        for (final encoder in encoders)
          FfmpegCommandBuilder.iphoneVideo(
            input: inputPath,
            output: output,
            encoder: encoder,
            height: job.request.height,
          ),
      ],
      output: output,
      onLine: (text) => parser.parseFfmpeg(text, step: .convertingForIphone),
    );
  }

  @override
  Stream<DownloadEvent> makeSlideshow(DownloadJob job, {required String imageDir, required String musicPath}) async* {
    final output = p.join(_directories.workFor(job.id), 'slideshow.mp4');
    final encoders = FfmpegCommandBuilder.iphoneEncoders(_info?.encoders ?? const []);
    yield* _runFfmpeg(
      job.id,
      step: .makingSlideshow,
      commands: [
        for (final encoder in encoders)
          FfmpegCommandBuilder.slideshow(
            imagePattern: p.join(imageDir, '%02d.jpg'),
            music: musicPath,
            output: output,
            encoder: encoder,
          ),
      ],
      output: output,
    );
  }

  /// Runs [commands] in order until one succeeds, holding the one ffmpeg slot
  /// so download re-encodes never run alongside conversions (see [FfmpegSlot]).
  Stream<DownloadEvent> _runFfmpeg(
    String jobId, {
    required ProcessingStep step,
    required List<List<String>> commands,
    required String output,
    JobProgress? Function(String line)? onLine,
  }) async* {
    yield DownloadProgressed(JobProgress(stage: .processing, step: step));
    final release = await _slot.acquire();
    try {
      var lastError = '';
      for (final args in commands) {
        await for (final event in _engine.ffmpeg(jobId, args)) {
          switch (event) {
            case EngineLine(:final text):
              if (onLine?.call(text) case final progress?) {
                yield DownloadProgressed(progress);
              }
            case EngineDone():
              yield DownloadFinished(mediaPath: output);
              return;
            case EngineFailed(:final output):
              lastError = output;
            case EngineCancelled():
              yield const DownloadCancelled();
              return;
          }
        }
      }
      yield DownloadFailed(lastError.isEmpty ? EngineMessages.convertFailed : EngineErrors.messageFor(lastError));
    } finally {
      release();
    }
  }

  @override
  Future<void> cancel(String jobId) => _engine.cancel(jobId);

  @override
  FutureData<String> updateEngine() async {
    final result = await _engine.updateYtDlp();
    return switch (result) {
      SuccessState(:final data?) => SuccessState(data: _rememberVersion(data)),
      final FailureState<String> failure => FailureState(
        message: EngineMessages.updateFailed,
        error: failure.error,
        actionPath: failure.actionPath,
        stackTrace: failure.stackTrace,
        errorId: failure.errorId,
      ),
      _ => const FailureState(message: EngineMessages.updateFailed),
    };
  }

  @override
  FutureData<EngineUpdate> checkForUpdate() async {
    final current = _info?.ytDlpVersion;
    final result = await _releases.latestYtDlpVersion();
    return switch (result) {
      SuccessState(:final data?) => SuccessState(
        data: EngineUpdate(
          latestVersion: data,
          available: current != null && _isNewer(data, than: current),
        ),
      ),
      final FailureState<String> failure => FailureState(
        message: EngineMessages.checkFailed,
        error: failure.error,
        actionPath: failure.actionPath,
        stackTrace: failure.stackTrace,
        errorId: failure.errorId,
      ),
      _ => const FailureState(message: EngineMessages.checkFailed),
    };
  }

  @override
  Future<void> clearWork(String jobId) async {
    try {
      await _files.delete(_directories.workFor(jobId));
    } on Object {
      // Leftovers are cleared at the next start anyway.
    }
  }

  /// The site's imported cookies.txt, else the browser setting (desktops).
  ({String? path, CookieBrowser browser}) _cookiesFor(Site site) {
    final browser = _settings.current.cookieBrowser;
    final available = CookieBrowser.availableOn(Platform.operatingSystem).contains(browser);
    return (path: _cookies.pathFor(site), browser: available ? browser : .none);
  }

  String _rememberVersion(String version) {
    if (_info case final info?) {
      _info = EngineInfo(ytDlpVersion: version, encoders: info.encoders);
    }
    return version;
  }

  /// yt-dlp versions are dates (`2026.11.23`, nightly `2026.11.23.123456`).
  static bool _isNewer(String latest, {required String than}) {
    final a = latest.split('.').map(int.tryParse).toList();
    final b = than.split('.').map(int.tryParse).toList();
    for (var index = 0; index < a.length; index++) {
      final x = a[index] ?? 0;
      final y = index < b.length ? b[index] ?? 0 : 0;
      if (x != y) {
        return x > y;
      }
    }
    return false;
  }

  /// Finds the downloaded file: the biggest file that isn't the thumbnail or a partial.
  Future<DownloadEvent> _finished(String workDir) async {
    final files = await _files.listFiles(workDir);
    String? thumbnail;
    String? media;
    var mediaSize = -1;
    for (final file in files) {
      final name = p.basename(file);
      if (name.startsWith('${YtDlpArgsBuilder.thumbnailStem}.')) {
        thumbnail = file;
        continue;
      }
      if (name.endsWith('.part') || name.endsWith('.ytdl')) {
        continue;
      }
      final size = await _files.sizeOf(file);
      if (size > mediaSize) {
        media = file;
        mediaSize = size;
      }
    }
    return media == null
        ? const DownloadFailed(EngineMessages.failed)
        : DownloadFinished(mediaPath: media, thumbnailPath: thumbnail);
  }
}

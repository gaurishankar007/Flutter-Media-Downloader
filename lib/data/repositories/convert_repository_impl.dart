import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/core/utils/filename_utils.dart';
import 'package:media_tool/data/repositories/helpers/local_media_reader.dart';
import 'package:media_tool/data/services/local/library_local_service.dart';
import 'package:media_tool/data/services/platform/image_convert_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/platform/media_engine/builders/ffmpeg_command_builder.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/ffmpeg_slot.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/data/services/platform/media_engine/parsers/ffmpeg_progress_parser.dart';
import 'package:media_tool/data/services/platform/media_picker_service.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/convert_request.dart';
import 'package:media_tool/domain/models/download_event.dart';
import 'package:media_tool/domain/models/image_compress_options.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/repositories/convert_repository.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

@LazySingleton(as: ConvertRepository)
final class ConvertRepositoryImpl({
  required final MediaEngine _engine,
  required final FfmpegSlot _slot,
  required final LocalMediaReader _reader,
  required final ImageConvertService _images,
  required final ImageService _thumbnails,
  required final MediaPickerService _picker,
  required final LibraryLocalService _library,
  required final AppDirectories _directories,
  required final FileService _files,
  required final ErrorHandler _errorHandler,
}) implements ConvertRepository {
  @override
  FutureData<LocalMediaInfo?> pickFromPhotos() => _pick(_picker.pickFromPhotos, action: 'convert.pickFromPhotos');

  @override
  FutureData<LocalMediaInfo?> pickFromFiles() => _pick(_picker.pickFromFiles, action: 'convert.pickFromFiles');

  @override
  FutureData<LocalMediaInfo> importFile(String path) =>
      _errorHandler.execute(action: 'convert.import', () => _reader.copyAndRead(path));

  @override
  FutureData<LocalMediaInfo> fromLibrary(String id) => _errorHandler.execute(action: 'convert.fromLibrary', () async {
    final items = await _library.getByIds([id]);
    if (items case final FailureState<List<LibraryItem>> failure) {
      return failure.retype();
    }
    final item = items.data?.firstOrNull;
    if (item == null || item.kind == .document) {
      return const FailureState(message: ConvertMessages.unreadable);
    }
    return await _reader.readLibraryItem(item);
  });

  @override
  Future<void> discard(LocalMediaInfo source) => _reader.discard(source);

  @override
  Future<List<ConvertFormat>> targetsFor(LocalMediaInfo source) async {
    final encoders = _reader.encoders;
    final targets = switch (source.kind) {
      .photo => _images.outputFormats,
      .audio => const [ConvertFormat.mp3, ConvertFormat.m4a],
      .document => const <ConvertFormat>[],
      .video => [
        ConvertFormat.mp4,
        ConvertFormat.mov,
        ConvertFormat.mkv,
        if (encoders.contains('libvpx-vp9')) ConvertFormat.webm,
        if (source.hasAudio) ...[ConvertFormat.mp3, ConvertFormat.m4a],
      ],
    };
    final own = ConvertFormat.fromExtension(source.format);
    return [
      for (final format in targets)
        if (format != own) format,
    ];
  }

  @override
  ConvertFormat? compressFormatFor(LocalMediaInfo source) => switch (source.kind) {
    .video => .mp4,
    .audio || .document => null,
    .photo => switch (ConvertFormat.fromExtension(source.format)) {
      final own? when _images.outputFormats.contains(own) => own,
      _ => .jpg,
    },
  };

  @override
  Stream<DownloadEvent> run(String jobId, ConvertRequest request) async* {
    final workDir = _directories.workFor(jobId);
    final output = p.join(workDir, 'output.${request.format.extension}');
    await _files.createDir(workDir);
    if (request.format.kind == .photo) {
      yield* _runImage(request, output, workDir);
      return;
    }

    yield const DownloadProgressed(JobProgress(stage: .queued));
    final release = await _slot.acquire();
    try {
      yield const DownloadProgressed(JobProgress(stage: .processing));
      var lastError = '';
      // Each command is a fallback for the one before (hardware encoders fail on some devices).
      for (final args in _commands(request, output)) {
        final parser = FfmpegProgressParser(durationSeconds: request.source.durationSeconds);
        await for (final event in _engine.ffmpeg(jobId, args)) {
          switch (event) {
            case EngineLine(:final text):
              if (parser.parse(text) case final progress?) {
                yield DownloadProgressed(progress);
              }
            case EngineDone():
              final thumbnail = request.format.kind == .video
                  ? await _reader.videoThumbnail(
                      jobId,
                      output,
                      p.join(workDir, 'thumb.jpg'),
                      request.source.durationSeconds,
                    )
                  : null;
              yield DownloadFinished(mediaPath: output, thumbnailPath: thumbnail);
              return;
            case EngineFailed(:final output):
              lastError = output;
            case EngineCancelled():
              yield const DownloadCancelled();
              return;
          }
        }
      }
      yield DownloadFailed(_messageFor(lastError));
    } finally {
      release();
    }
  }

  @override
  FutureData<LibraryItem> save(ConvertRequest request, {required String outputPath, String? thumbnailPath}) =>
      _errorHandler.execute(action: 'convert.save', () async {
        final source = request.source;
        final origin = switch (source.libraryItemId) {
          final id? => (await _library.getByIds([id])).data?.firstOrNull,
          null => null,
        };
        final id = const Uuid().v4();
        final extension = request.format.extension;
        final name = FilenameUtils.fromTitle(
          source.title,
          extension: extension,
          suffix: request.scalesDown ? '[${request.outputHeight}p]' : null,
          fallback: 'converted',
        );
        final target = p.join(_directories.downloads, _files.uniqueName(_directories.downloads, name));
        await _files.move(outputPath, target);

        String? thumbnailTarget;
        if (thumbnailPath != null) {
          thumbnailTarget = p.join(_directories.thumbnails, '$id.jpg');
          await _files.move(thumbnailPath, thumbnailTarget);
        }

        final kind = request.format.kind;
        final item = LibraryItem(
          id: id,
          kind: kind,
          title: source.title,
          site: origin?.site,
          uploader: origin?.uploader,
          sourceUrl: origin?.sourceUrl,
          relativePath: _directories.relative(target),
          thumbnailRelativePath: thumbnailTarget == null ? null : _directories.relative(thumbnailTarget),
          sizeBytes: await _files.sizeOf(target),
          durationMs: kind == .photo || source.durationSeconds == null
              ? null
              : (source.durationSeconds! * 1000).round(),
          format: extension,
          createdAt: DateTime.now(),
        );
        final inserted = await _library.insert(item, origin: 'convert');
        if (inserted case final FailureState<void> failure) {
          // Don't leave a file the Library doesn't know about.
          await _files.delete(target);
          if (thumbnailTarget != null) {
            await _files.delete(thumbnailTarget);
          }
          return failure.retype();
        }
        return SuccessState(data: item);
      });

  @override
  Future<void> cancel(String jobId) => _engine.cancel(jobId);

  @override
  Future<void> clearWork(String jobId) => _errorHandler.executeSafe(() => _files.delete(_directories.workFor(jobId)));

  FutureData<LocalMediaInfo?> _pick(Future<String?> Function() pick, {required String action}) =>
      _errorHandler.execute(action: action, () async {
        final path = await pick();
        if (path == null) {
          return const SuccessState(data: null);
        }
        final read = await _reader.copyAndRead(path);
        await _picker.clearTemporaryFiles();
        return read.mapData<LocalMediaInfo?>((info) => info);
      });

  /// The ffmpeg commands for [request], best first; later ones are fallbacks.
  /// See docs/engine/ffmpeg_recipes.md#convert.
  List<List<String>> _commands(ConvertRequest request, String output) {
    final source = request.source;
    final input = source.path;
    final encoders = FfmpegCommandBuilder.iphoneEncoders(_reader.encoders);
    List<List<String>> iphone() => [
      for (final encoder in encoders)
        FfmpegCommandBuilder.iphoneVideo(input: input, output: output, encoder: encoder, height: source.shortSide),
    ];

    if (request.isCompress) {
      final preset = request.preset;
      return [
        for (final encoder in encoders)
          FfmpegCommandBuilder.compressVideo(
            input: input,
            output: output,
            encoder: encoder,
            crf: preset.crf,
            toolboxQuality: preset.toolboxQuality,
            presetKbps: preset.videoKbps(request.outputHeight ?? 1080),
            audioKbps: request.audioKbps,
            scaleHeight: request.scalesDown ? request.outputHeight : null,
            portrait: source.isPortrait,
            videoKbps: request.targetVideoKbps,
          ),
      ];
    }
    return switch (request.format) {
      .mp3 => [FfmpegCommandBuilder.audio(input: input, output: output, mp3: true)],
      .m4a => [FfmpegCommandBuilder.audio(input: input, output: output, mp3: false, copyAac: source.hasAacAudio)],
      .webm => [FfmpegCommandBuilder.webm(input: input, output: output)],
      .mkv => [FfmpegCommandBuilder.remux(input: input, output: output)],
      .mp4 || .mov when request.copiesVideo => [
        FfmpegCommandBuilder.remux(
          input: input,
          output: output,
          hevcTag: source.videoCodec == 'hevc',
          aacAudio: source.hasAudio && !source.hasAacAudio && request.iphoneCompatible,
          faststart: true,
        ),
        // Some codecs can't go into MP4 / MOV as they are: re-encode instead.
        if (!source.hasIphoneVideo) ...iphone(),
      ],
      .mp4 || .mov => iphone(),
      _ => const [],
    };
  }

  Stream<DownloadEvent> _runImage(ConvertRequest request, String output, String workDir) async* {
    yield const DownloadProgressed(JobProgress(stage: .processing));
    final source = request.source;
    final options = request.imageOptions;
    int? shortSide;
    if (request.isCompress && source.shortSide != null && source.longSide != null) {
      final factor = switch (options) {
        ImageCompressOptions(longestSide: final side?) => side / source.longSide!,
        ImageCompressOptions(percent: final percent?) => percent / 100,
        _ => 1.0,
      };
      if (factor < 1) {
        shortSide = (source.shortSide! * factor).round();
      }
    }
    final converted = await _errorHandler.execute(action: 'convert.image', () async {
      await _images.convert(
        source.path,
        output,
        format: request.format,
        quality: request.isCompress ? options.quality : 92,
        shortSide: shortSide,
        keepMetadata: !request.isCompress || !options.stripMetadata,
      );
      return const SuccessState<void>.nil();
    });
    if (converted is FailureState) {
      yield DownloadFailed(ConvertMessages.imageFailed(request.format.label));
      return;
    }
    final thumbnail = p.join(workDir, 'thumb.jpg');
    final hasThumbnail = await _errorHandler.executeSafeReturn(() async {
      await _thumbnails.thumbnail(output, thumbnail);
      return true;
    }, onError: (_) => false);
    yield DownloadFinished(mediaPath: output, thumbnailPath: hasThumbnail ? thumbnail : null);
  }

  static String _messageFor(String output) =>
      output.contains('No space left') ? CommonMessages.noSpace : ConvertMessages.failed;
}

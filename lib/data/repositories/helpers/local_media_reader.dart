import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/local_media_info_dto.dart';
import 'package:media_tool/data/services/platform/image_convert_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/platform/media_engine/builders/ffmpeg_command_builder.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/data/services/platform/media_engine/parsers/ffmpeg_info_parser.dart';
import 'package:media_tool/data/services/platform/pdf_service.dart';
import 'package:media_tool/domain/models/engine_info.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Reads local files (picked, dropped or from the Library) into
/// [LocalMediaInfo] for the converter and the tools: images with the image
/// decoder, PDFs with PDFium, video / audio with `ffmpeg -i`. Also keeps the
/// engine's encoder list. Shared by ConvertRepositoryImpl and ToolRepositoryImpl.
@lazySingleton
final class LocalMediaReader({
  required final MediaEngine _engine,
  required final ImageConvertService _images,
  required final ImageService _thumbnails,
  required final PdfService _pdf,
  required final AppDirectories _directories,
  required final FileService _files,
  required final ErrorHandler _errorHandler,
}) {
  static const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'gif', 'bmp'};
  static const _audioExtensions = {'mp3', 'm4a', 'aac', 'opus', 'ogg', 'wav', 'flac'};
  static const _sourceThumbnail = 'source-thumb.jpg';

  List<String>? _encoders;

  /// The engine's encoders, once [ensureEngine] has run (empty before).
  List<String> get encoders => _encoders ?? const [];

  /// Copies [path] into its own `work/` folder (so the original is never
  /// touched or locked) and reads the copy.
  FutureData<LocalMediaInfo> copyAndRead(String path) async {
    final folder = _directories.workFor('source-${const Uuid().v4()}');
    final copy = p.join(folder, p.basename(path));
    await _files.copy(path, copy);
    final read = await this.read(copy, title: p.basenameWithoutExtension(path));
    if (read is FailureState) {
      await _files.delete(folder);
    }
    return read;
  }

  /// Reads a Library item's file in place.
  FutureData<LocalMediaInfo> readLibraryItem(LibraryItem item) => read(
    _directories.resolve(item.relativePath),
    title: item.title,
    kind: item.kind,
    libraryItemId: item.id,
    thumbnailPath: item.thumbnailRelativePath == null ? null : _directories.resolve(item.thumbnailRelativePath!),
  );

  /// Deletes a picked file's working copy. Library files are left alone.
  Future<void> discard(LocalMediaInfo source) => _errorHandler.executeSafe(() async {
    final folder = p.dirname(source.path);
    if (source.libraryItemId == null && p.isWithin(_directories.work, folder)) {
      await _files.delete(folder);
    }
  });

  FutureData<LocalMediaInfo> read(
    String path, {
    required String title,
    MediaKind? kind,
    String? libraryItemId,
    String? thumbnailPath,
  }) async {
    final format = p.extension(path).replaceFirst('.', '').toLowerCase();
    final sizeBytes = await _files.sizeOf(path);
    if (kind == .document || format == 'pdf') {
      return await _readPdf(
        path,
        title: title,
        sizeBytes: sizeBytes,
        libraryItemId: libraryItemId,
        thumbnailPath: thumbnailPath,
      );
    }
    final isImage = kind == .photo || (kind == null && imageExtensions.contains(format));
    final engine = await ensureEngine();
    if (engine case final FailureState<void> failure when !isImage) {
      return failure.retype();
    }

    if (isImage) {
      final size = await _images.sizeOf(path);
      return SuccessState(
        data: LocalMediaInfo(
          path: path,
          title: title,
          kind: .photo,
          format: format,
          sizeBytes: sizeBytes,
          libraryItemId: libraryItemId,
          thumbnailPath: thumbnailPath ?? path,
          width: size?.width,
          height: size?.height,
        ),
      );
    }

    var output = '';
    await for (final event in _engine.ffmpeg('probe-${const Uuid().v4()}', FfmpegCommandBuilder.probe(path))) {
      if (event case EngineFailed(output: final text)) {
        output = text;
      }
    }
    final dto = FfmpegInfoParser.parse(output);
    final detected = switch (dto) {
      _ when kind == .audio || _audioExtensions.contains(format) => dto?.audioCodec == null ? null : MediaKind.audio,
      LocalMediaInfoDto(videoCodec: _?) => MediaKind.video,
      LocalMediaInfoDto(audioCodec: _?) => MediaKind.audio,
      _ => null,
    };
    if (dto == null || detected == null) {
      return FailureState(message: ConvertMessages.unreadable, error: _tail(output));
    }
    final ownThumbnail =
        thumbnailPath ??
        (detected == .video && libraryItemId == null
            ? await videoThumbnail(
                'thumb-${const Uuid().v4()}',
                path,
                p.join(p.dirname(path), _sourceThumbnail),
                dto.durationSeconds,
              )
            : null);
    return SuccessState(
      data: LocalMediaInfo(
        path: path,
        title: title,
        kind: detected,
        format: format,
        sizeBytes: sizeBytes,
        libraryItemId: libraryItemId,
        thumbnailPath: ownThumbnail,
        durationSeconds: dto.durationSeconds,
        width: dto.width,
        height: dto.height,
        videoCodec: detected == .video ? dto.videoCodec : null,
        audioCodec: dto.audioCodec,
        audioKbps: dto.audioKbps,
      ),
    );
  }

  /// Starts the engine once (it's usually already running) and keeps its encoder list.
  FutureVoid ensureEngine() async {
    if (_encoders != null) {
      return const SuccessState.nil();
    }
    final result = await _engine.init();
    if (result case SuccessState(:final data?)) {
      _encoders = data.encoders;
      return const SuccessState.nil();
    }
    return switch (result) {
      final FailureState<EngineInfo> failure => failure.retype(),
      _ => const FailureState(),
    };
  }

  /// A frame at 10% of the video as a small JPG, or null when ffmpeg can't.
  Future<String?> videoThumbnail(String jobId, String input, String output, double? durationSeconds) async {
    final args = FfmpegCommandBuilder.thumbnail(input: input, output: output, atSeconds: (durationSeconds ?? 0) * 0.1);
    await for (final event in _engine.ffmpeg(jobId, args)) {
      if (event is EngineDone) {
        return output;
      }
    }
    return null;
  }

  /// A small JPG of [pdf]'s first page written to [output], or null when it
  /// can't be rendered (encrypted, damaged).
  Future<String?> pdfThumbnail(String pdf, String output, {String? password}) =>
      _errorHandler.executeSafeReturn(() async {
        final folder = p.join(p.dirname(output), 'thumb-${const Uuid().v4()}');
        try {
          final page = await _pdf.renderPages(pdf, folder, maxSide: 720, pages: const [0], password: password).first;
          await _thumbnails.thumbnail(page, output);
          return output;
        } finally {
          await _files.delete(folder);
        }
      }, onError: (_) => null);

  FutureData<LocalMediaInfo> _readPdf(
    String path, {
    required String title,
    required int sizeBytes,
    String? libraryItemId,
    String? thumbnailPath,
  }) async {
    final info = await _errorHandler.executeSafeReturn<PdfInfo?>(() => _pdf.info(path), onError: (_) => null);
    if (info == null) {
      return const FailureState(message: ToolsMessages.unreadablePdf);
    }
    final thumbnail =
        thumbnailPath ??
        (libraryItemId == null && !info.needsPassword
            ? await pdfThumbnail(path, p.join(p.dirname(path), _sourceThumbnail))
            : null);
    return SuccessState(
      data: LocalMediaInfo(
        path: path,
        title: title,
        kind: .document,
        format: 'pdf',
        sizeBytes: sizeBytes,
        libraryItemId: libraryItemId,
        thumbnailPath: thumbnail,
        pageCount: info.pageCount,
        encrypted: info.needsPassword,
      ),
    );
  }

  static String _tail(String text) => text.length > 600 ? text.substring(text.length - 600) : text;
}

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/core/utils/filename_utils.dart';
import 'package:media_tool/data/repositories/helpers/local_media_reader.dart';
import 'package:media_tool/data/repositories/helpers/media_tool_runner.dart';
import 'package:media_tool/data/repositories/helpers/pdf_tool_runner.dart';
import 'package:media_tool/data/services/local/library_local_service.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/data/services/platform/media_picker_service.dart';
import 'package:media_tool/data/services/platform/pdf_service.dart';
import 'package:media_tool/domain/models/library_item.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/pick_source.dart';
import 'package:media_tool/domain/models/tool_event.dart';
import 'package:media_tool/domain/models/tool_input.dart';
import 'package:media_tool/domain/models/tool_output.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:media_tool/domain/repositories/tool_repository.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

@LazySingleton(as: ToolRepository)
final class ToolRepositoryImpl({
  required final LocalMediaReader _reader,
  required final PdfToolRunner _pdfRunner,
  required final MediaToolRunner _mediaRunner,
  required final PdfService _pdf,
  required final MediaEngine _engine,
  required final MediaPickerService _picker,
  required final LibraryLocalService _library,
  required final AppDirectories _directories,
  required final FileService _files,
  required final ErrorHandler _errorHandler,
}) implements ToolRepository {
  @override
  FutureList<LocalMediaInfo> pick(ToolInput input, {required PickSource from, required bool multiple}) =>
      _errorHandler.execute(action: 'tools.pick', () async {
        final paths = await _picker.pickMany(
          filter: switch (input) {
            .images => .images,
            .video => .videos,
            .pdf || .gif => .extensions,
          },
          fromPhotos: from == .photos,
          multiple: multiple,
          extensions: input.extensions,
        );
        try {
          return await _readAll(paths, input, _reader.copyAndRead);
        } finally {
          await _picker.clearTemporaryFiles();
        }
      });

  @override
  FutureList<LocalMediaInfo> fromLibrary(List<String> ids) =>
      _errorHandler.execute(action: 'tools.fromLibrary', () async {
        final items = await _library.getByIds(ids);
        if (items case final FailureState<List<LibraryItem>> failure) {
          return failure.retype();
        }
        final byId = {for (final item in items.data ?? const <LibraryItem>[]) item.id: item};
        final sources = <LocalMediaInfo>[];
        for (final id in ids) {
          if (byId[id] case final item?) {
            final read = await _reader.readLibraryItem(item);
            if (read case final FailureState<LocalMediaInfo> failure) {
              return failure.retype();
            }
            sources.add(read.data!);
          }
        }
        return SuccessState(data: sources);
      });

  @override
  Future<void> discard(List<LocalMediaInfo> sources) async {
    for (final source in sources) {
      await _reader.discard(source);
    }
  }

  @override
  FutureList<String> pageThumbnails(LocalMediaInfo pdf) =>
      _errorHandler.execute(action: 'tools.pageThumbnails', () async {
        final folder = _directories.workFor('pages-${const Uuid().v4()}');
        final pages = await _pdf.renderPages(pdf.path, folder, maxSide: 360).toList();
        return SuccessState(data: pages);
      });

  @override
  Stream<ToolEvent> run(String jobId, ToolRequest request) async* {
    final workDir = _directories.workFor(jobId);
    await _files.createDir(workDir);
    if (request.sources.any((source) => source.encrypted) && request is! UnlockPdfRequest) {
      yield const ToolFailed(ToolsMessages.lockedPdf);
      return;
    }
    yield* switch (request) {
      final PdfToolRequest pdf => _pdfRunner.run(jobId, pdf, workDir),
      final MediaToolRequest media => _mediaRunner.run(jobId, media, workDir),
    };
  }

  @override
  FutureList<LibraryItem> save(ToolRequest request, List<ToolOutput> outputs) =>
      _errorHandler.execute(action: 'tools.save', () async {
        final first = request.sources.first;
        final origin = switch (first.libraryItemId) {
          final id? => (await _library.getByIds([id])).data?.firstOrNull,
          null => null,
        };
        final title = switch (request) {
          MergePdfRequest() => ToolsMessages.mergedTitle(first.title),
          ImagesToPdfRequest() ||
          ImagesToGifRequest() when request.sources.length > 1 => ToolsMessages.imagesTitle(first.title),
          _ => first.title,
        };
        final groupId = outputs.length > 1 ? const Uuid().v4() : null;
        final createdAt = DateTime.now();
        final items = <LibraryItem>[];
        final moved = <String>[];
        for (final (index, output) in outputs.indexed) {
          final id = const Uuid().v4();
          final extension = p.extension(output.path).replaceFirst('.', '').toLowerCase();
          final name = FilenameUtils.fromTitle(
            title,
            extension: extension,
            suffix: groupId == null ? null : (index + 1).toString().padLeft(2, '0'),
            fallback: 'file',
          );
          final target = p.join(_directories.downloads, _files.uniqueName(_directories.downloads, name));
          await _files.move(output.path, target);
          moved.add(target);
          String? thumbnail;
          if (output.thumbnailPath case final still?) {
            thumbnail = p.join(_directories.thumbnails, '$id.jpg');
            await _files.move(still, thumbnail);
            moved.add(thumbnail);
          }
          items.add(
            LibraryItem(
              id: id,
              kind: output.kind,
              title: groupId == null ? title : '$title ${index + 1}',
              site: origin?.site,
              uploader: origin?.uploader,
              sourceUrl: origin?.sourceUrl,
              relativePath: _directories.relative(target),
              thumbnailRelativePath: thumbnail == null ? null : _directories.relative(thumbnail),
              sizeBytes: await _files.sizeOf(target),
              durationMs: output.durationMs,
              format: extension,
              // Keeps the outputs' order when sorted newest first.
              createdAt: createdAt.subtract(Duration(milliseconds: index)),
              groupId: groupId,
              groupIndex: groupId == null ? null : index,
            ),
          );
        }
        for (final item in items) {
          final inserted = await _library.insert(item, origin: 'tool');
          if (inserted case final FailureState<void> failure) {
            // Don't leave files the Library doesn't know about.
            await _library.deleteByIds([for (final item in items) item.id]);
            for (final path in moved) {
              await _files.delete(path);
            }
            return failure.retype();
          }
        }
        return SuccessState(data: items);
      });

  @override
  Future<void> cancel(String jobId) async {
    _pdfRunner.cancel(jobId);
    _mediaRunner.cancel(jobId);
    await _engine.cancel(jobId);
  }

  @override
  Future<void> clearWork(String jobId) => _errorHandler.executeSafe(() => _files.delete(_directories.workFor(jobId)));

  /// Reads every path of the right type. Fails only when none could be read.
  FutureList<LocalMediaInfo> _readAll(
    List<String> paths,
    ToolInput input,
    FutureData<LocalMediaInfo> Function(String path) read,
  ) async {
    final sources = <LocalMediaInfo>[];
    DataState<LocalMediaInfo>? lastFailure;
    for (final path in paths) {
      final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
      if (!input.extensions.contains(extension)) {
        lastFailure = FailureState(message: _wrongType(input));
        continue;
      }
      final result = await read(path);
      switch (result) {
        case SuccessState(:final data?):
          sources.add(data);
        default:
          lastFailure = result;
      }
    }
    if (lastFailure case final FailureState<LocalMediaInfo> failure when sources.isEmpty) {
      return failure.retype();
    }
    return SuccessState(data: sources);
  }

  static String _wrongType(ToolInput input) => switch (input) {
    .images => ToolsMessages.wrongTypeImages,
    .pdf => ToolsMessages.wrongTypePdf,
    .video => ToolsMessages.wrongTypeVideo,
    .gif => ToolsMessages.wrongTypeGif,
  };
}

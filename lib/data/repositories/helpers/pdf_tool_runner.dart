import 'package:injectable/injectable.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/data/repositories/helpers/local_media_reader.dart';
import 'package:media_tool/data/repositories/helpers/tool_runner_steps.dart';
import 'package:media_tool/data/services/platform/image_convert_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/platform/pdf_service.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/tool_event.dart';
import 'package:media_tool/domain/models/tool_output.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:path/path.dart' as p;

/// Runs the PDF tools with PDFium and the `pdf` package (no ffmpeg, so no
/// slot to wait for). Each step checks the cancel flag.
/// See docs/features/tools.md#pdf-tools.
@lazySingleton
final class PdfToolRunner({
  required final PdfService _pdf,
  required final ImageService _images,
  required final ImageConvertService _decoder,
  required final LocalMediaReader _reader,
  required final FileService _files,
  required final ErrorHandler _errorHandler,
}) with ToolRunnerSteps {
  @override
  ErrorHandler get errorHandler => _errorHandler;

  Stream<ToolEvent> run(String jobId, PdfToolRequest request, String workDir) async* {
    try {
      yield const ToolProgressed(JobProgress(stage: .processing));
      yield* switch (request) {
        final ImagesToPdfRequest request => _imagesToPdf(jobId, request, workDir),
        final PdfToImagesRequest request => _pdfToImages(jobId, request, workDir),
        final MergePdfRequest request => _assembleOne(jobId, workDir, [
          for (final source in request.sources)
            for (var index = 0; index < (source.pageCount ?? 0); index++)
              (path: source.path, index: index, quarterTurns: 0),
        ]),
        final SplitPdfRequest request => _split(jobId, request, workDir),
        final OrganizePdfRequest request => _assembleOne(jobId, workDir, [
          for (final page in request.pages)
            (path: request.source.path, index: page.index, quarterTurns: page.quarterTurns),
        ]),
        final CompressPdfRequest request => _compress(jobId, request, workDir),
        final UnlockPdfRequest request => _unlock(request, workDir),
      };
    } finally {
      finish(jobId);
    }
  }

  Stream<ToolEvent> _imagesToPdf(String jobId, ImagesToPdfRequest request, String workDir) async* {
    final jpegs = <({String path, int width, int height})>[];
    for (final (index, source) in request.sources.indexed) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      // JPGs at full size with the rotation applied: the `pdf` package embeds them as they are.
      final jpg = p.join(workDir, 'image-${index + 1}.jpg');
      final failed = await attempt('tools.imagesToPdf.image', () async {
        await _images.toJpg(source.path, jpg);
        final size = await _decoder.sizeOf(jpg);
        jpegs.add((path: jpg, width: size?.width ?? 1, height: size?.height ?? 1));
      }, fallback: ToolsMessages.imageUnreadable(source.title));
      if (failed != null) {
        yield ToolFailed(failed);
        return;
      }
      yield ToolRunnerSteps.progress((index + 1) / (request.sources.length + 1));
    }
    final output = p.join(workDir, 'output.pdf');
    final failed = await attempt(
      'tools.imagesToPdf.write',
      () => _pdf.imagesToPdf(
        jpegs,
        output,
        paper: request.paper,
        orientation: request.orientation,
        margin: request.margin,
      ),
      fallback: ToolsMessages.pdfFailed,
    );
    if (failed != null) {
      yield ToolFailed(failed);
      return;
    }
    yield ToolFinished([await _document(output, workDir)]);
  }

  Stream<ToolEvent> _pdfToImages(String jobId, PdfToImagesRequest request, String workDir) async* {
    final pages = request.source.pageCount ?? 1;
    final outputs = <ToolOutput>[];
    final rendered = p.join(workDir, 'pages');
    String? failed;
    var index = 0;
    final stream = _errorHandler.executeStream(
      _pdf.renderPages(request.source.path, rendered, dpi: request.dpi.dpi),
      action: 'tools.pdfToImages.render',
    );
    await for (final result in stream) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final png = result.data;
      if (png == null) {
        failed = result.message;
        break;
      }
      index++;
      final number = index.toString().padLeft(3, '0');
      final image = request.format == .png ? png : p.join(workDir, 'page-$number.jpg');
      final thumbnail = p.join(workDir, 'thumb-$number.jpg');
      failed = await attempt('tools.pdfToImages.encode', () async {
        if (image != png) {
          await _images.toJpg(png, image, quality: 90);
          await _files.delete(png);
        }
        await _images.thumbnail(image, thumbnail);
      }, fallback: ToolsMessages.pdfFailed);
      if (failed != null) {
        break;
      }
      outputs.add(ToolOutput(path: image, kind: .photo, thumbnailPath: thumbnail));
      yield ToolRunnerSteps.progress(index / pages);
    }
    if (failed != null || outputs.isEmpty) {
      yield ToolFailed(failed ?? ToolsMessages.pdfFailed);
      return;
    }
    yield ToolFinished(outputs);
  }

  Stream<ToolEvent> _split(String jobId, SplitPdfRequest request, String workDir) async* {
    final outputs = <ToolOutput>[];
    for (final (index, group) in request.groups.indexed) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final output = p.join(workDir, 'part-${(index + 1).toString().padLeft(3, '0')}.pdf');
      final failed = await attempt(
        'tools.splitPdf',
        () => _pdf.assemble([
          for (final page in group) (path: request.source.path, index: page, quarterTurns: 0),
        ], output),
        fallback: ToolsMessages.pdfFailed,
      );
      if (failed != null) {
        yield ToolFailed(failed);
        return;
      }
      outputs.add(await _document(output, workDir));
      yield ToolRunnerSteps.progress((index + 1) / request.groups.length);
    }
    yield ToolFinished(outputs);
  }

  Stream<ToolEvent> _assembleOne(String jobId, String workDir, List<PdfPageSource> pages) async* {
    if (pages.isEmpty) {
      yield const ToolFailed(ToolsMessages.noPages);
      return;
    }
    final output = p.join(workDir, 'output.pdf');
    final failed = await attempt(
      'tools.assemblePdf',
      () => _pdf.assemble(pages, output),
      fallback: ToolsMessages.pdfFailed,
    );
    if (isCancelled(jobId)) {
      yield const ToolCancelled();
      return;
    }
    if (failed != null) {
      yield ToolFailed(failed);
      return;
    }
    yield ToolFinished([await _document(output, workDir)]);
  }

  Stream<ToolEvent> _compress(String jobId, CompressPdfRequest request, String workDir) async* {
    final source = request.source;
    final level = request.level;
    var sizes = const <({double width, double height})>[];
    var failed = await attempt('tools.compressPdf.sizes', () async {
      sizes = await _pdf.pageSizes(source.path);
    }, fallback: ToolsMessages.pdfFailed);
    if (failed != null) {
      yield ToolFailed(failed);
      return;
    }
    final pages = <PdfJpegPage>[];
    final stream = _errorHandler.executeStream(
      _pdf.renderPages(source.path, p.join(workDir, 'pages'), dpi: level.dpi),
      action: 'tools.compressPdf.render',
    );
    await for (final result in stream) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final png = result.data;
      if (png == null) {
        failed = result.message;
        break;
      }
      final index = pages.length;
      final jpg = p.join(workDir, 'page-${index + 1}.jpg');
      failed = await attempt('tools.compressPdf.encode', () async {
        await _images.toJpg(png, jpg, quality: level.quality);
        await _files.delete(png);
      }, fallback: ToolsMessages.pdfFailed);
      if (failed != null) {
        break;
      }
      pages.add((path: jpg, width: sizes[index].width, height: sizes[index].height));
      yield ToolRunnerSteps.progress(pages.length / (sizes.length + 1));
    }
    if (failed != null || pages.isEmpty) {
      yield ToolFailed(failed ?? ToolsMessages.pdfFailed);
      return;
    }
    final output = p.join(workDir, 'output.pdf');
    failed = await attempt(
      'tools.compressPdf.write',
      () => _pdf.jpegPagesToPdf(pages, output),
      fallback: ToolsMessages.pdfFailed,
    );
    if (failed != null) {
      yield ToolFailed(failed);
      return;
    }
    yield ToolFinished([await _document(output, workDir)]);
  }

  Stream<ToolEvent> _unlock(UnlockPdfRequest request, String workDir) async* {
    final output = p.join(workDir, 'output.pdf');
    final password = request.password.isEmpty ? null : request.password;
    final failed = await attempt(
      'tools.unlockPdf',
      () => _pdf.unlock(request.source.path, output, password: password),
      fallback: ToolsMessages.pdfFailed,
    );
    if (failed != null) {
      yield ToolFailed(failed);
      return;
    }
    yield ToolFinished([await _document(output, workDir)]);
  }

  /// A PDF output with a thumbnail of its first page.
  Future<ToolOutput> _document(String path, String workDir) async {
    final thumbnail = await _reader.pdfThumbnail(
      path,
      p.join(workDir, '${p.basenameWithoutExtension(path)}-thumb.jpg'),
    );
    return ToolOutput(path: path, kind: .document, thumbnailPath: thumbnail);
  }
}

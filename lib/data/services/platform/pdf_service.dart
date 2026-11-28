import 'dart:io';
import 'dart:ui' as ui;

import 'package:injectable/injectable.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

/// What PDFium read from a PDF: its page count, or that it needs a password.
typedef PdfInfo = ({int? pageCount, bool needsPassword});

/// One page of an assembled PDF: page `index` (0-based) of the PDF at `path`,
/// turned `quarterTurns` clockwise on top of its own rotation.
typedef PdfPageSource = ({String path, int index, int quarterTurns});

/// One JPEG page of a PDF: the image fills a page of `width` × `height` points.
typedef PdfJpegPage = ({String path, double width, double height});

/// PDF reading, rendering and writing on every platform: PDFium (pdfrx) opens,
/// renders, re-assembles and unlocks PDFs; the `pdf` package lays images out
/// on pages. Methods throw ([PdfPasswordException] when a password is needed
/// or wrong); repositories call them inside `ErrorHandler.execute`.
/// See docs/features/tools.md#pdf-tools.
abstract interface class PdfService {
  Future<PdfInfo> info(String path);

  /// Page sizes in points (rotation applied), in order.
  Future<List<({double width, double height})>> pageSizes(String path, {String? password});

  /// Renders pages to PNGs in [outputDir] (`page-001.png`…) at [dpi], or with
  /// the long side at [maxSide] pixels, yielding each written path in order.
  /// [pages] limits it to those 0-based indexes.
  Stream<String> renderPages(
    String path,
    String outputDir, {
    int? dpi,
    int? maxSide,
    List<int>? pages,
    String? password,
  });

  /// One page per JPEG at [paper] size and [orientation] with [margin]
  /// around the image (scaled to fit, centred). [jpegs] hold their pixel sizes.
  Future<void> imagesToPdf(
    List<({String path, int width, int height})> jpegs,
    String output, {
    required PdfPaperSize paper,
    required PdfOrientation orientation,
    required PdfMargin margin,
  });

  /// Each JPEG fills a page of the given size (Compress PDF).
  Future<void> jpegPagesToPdf(List<PdfJpegPage> pages, String output);

  /// A new PDF made of [pages] (from one or several PDFs), in order. Links,
  /// forms and bookmarks may not survive; page content does.
  Future<void> assemble(List<PdfPageSource> pages, String output, {Map<String, String> passwords = const {}});

  /// Saves the PDF at [path] without its password and restrictions.
  Future<void> unlock(String path, String output, {String? password});
}

@LazySingleton(as: PdfService)
final class PdfServiceImpl implements PdfService {
  static const _pixelsPerPoint = 96 / 72;

  bool _initialized = false;

  @override
  Future<PdfInfo> info(String path) async {
    await _init();
    try {
      final document = await PdfDocument.openFile(path);
      final count = document.pages.length;
      await document.dispose();
      return (pageCount: count, needsPassword: false);
    } on PdfPasswordException {
      return (pageCount: null, needsPassword: true);
    }
  }

  @override
  Future<List<({double width, double height})>> pageSizes(String path, {String? password}) async {
    final document = await _open(path, password);
    try {
      return [for (final page in document.pages) (width: page.width, height: page.height)];
    } finally {
      await document.dispose();
    }
  }

  @override
  Stream<String> renderPages(
    String path,
    String outputDir, {
    int? dpi,
    int? maxSide,
    List<int>? pages,
    String? password,
  }) async* {
    final document = await _open(path, password);
    try {
      await Directory(outputDir).create(recursive: true);
      final indexes = pages ?? [for (var index = 0; index < document.pages.length; index++) index];
      for (final index in indexes) {
        final page = document.pages[index];
        final scale = switch ((dpi, maxSide)) {
          (final dpi?, _) => dpi / 72,
          (_, final side?) => side / (page.width > page.height ? page.width : page.height),
          _ => _pixelsPerPoint,
        };
        final rendered = await page.render(fullWidth: page.width * scale, fullHeight: page.height * scale);
        if (rendered == null) {
          throw StateError('PDFium could not render page ${index + 1}');
        }
        final ui.Image image;
        try {
          image = await rendered.createImage();
        } finally {
          rendered.dispose();
        }
        final data = await image.toByteData(format: .png);
        image.dispose();
        if (data == null) {
          throw StateError('Could not encode page ${index + 1}');
        }
        final output = p.join(outputDir, 'page-${(index + 1).toString().padLeft(3, '0')}.png');
        await File(output).writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        yield output;
      }
    } finally {
      await document.dispose();
    }
  }

  @override
  Future<void> imagesToPdf(
    List<({String path, int width, int height})> jpegs,
    String output, {
    required PdfPaperSize paper,
    required PdfOrientation orientation,
    required PdfMargin margin,
  }) async {
    final document = pw.Document();
    for (final jpeg in jpegs) {
      final image = pw.MemoryImage(await File(jpeg.path).readAsBytes());
      final landscapeImage = jpeg.width > jpeg.height;
      final (width, height) = switch ((paper.width, paper.height)) {
        (final width?, final height?) => switch (orientation) {
          .portrait => (width, height),
          .landscape => (height, width),
          .auto => landscapeImage ? (height, width) : (width, height),
        },
        // Fit: the page is the image's size (at 96 dpi) plus the margin.
        _ => (jpeg.width / _pixelsPerPoint + margin.points * 2, jpeg.height / _pixelsPerPoint + margin.points * 2),
      };
      document.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(width, height, marginAll: margin.points),
          build: (_) => pw.Center(child: pw.Image(image)),
        ),
      );
    }
    await File(output).writeAsBytes(await document.save());
  }

  @override
  Future<void> jpegPagesToPdf(List<PdfJpegPage> pages, String output) async {
    final document = pw.Document();
    for (final page in pages) {
      final image = pw.MemoryImage(await File(page.path).readAsBytes());
      document.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(page.width, page.height),
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    await File(output).writeAsBytes(await document.save());
  }

  @override
  Future<void> assemble(List<PdfPageSource> pages, String output, {Map<String, String> passwords = const {}}) async {
    final opened = <String, PdfDocument>{};
    PdfDocument? target;
    try {
      for (final path in {for (final page in pages) page.path}) {
        opened[path] = await _open(path, passwords[path]);
      }
      target = (await PdfDocument.createNew(sourceName: output))
        ..pages = [
          for (final page in pages)
            opened[page.path]!.pages[page.index].rotatedBy(PdfPageRotation.values[page.quarterTurns % 4]),
        ];
      // Assembles first, so the sources can be closed afterwards.
      final bytes = await target.encodePdf();
      await File(output).writeAsBytes(bytes);
    } finally {
      await target?.dispose();
      for (final document in opened.values) {
        await document.dispose();
      }
    }
  }

  @override
  Future<void> unlock(String path, String output, {String? password}) async {
    final document = await _open(path, password);
    try {
      final bytes = await document.encodePdf(removeSecurity: true);
      await File(output).writeAsBytes(bytes);
    } finally {
      await document.dispose();
    }
  }

  Future<PdfDocument> _open(String path, String? password) async {
    await _init();
    return await PdfDocument.openFile(path, passwordProvider: createSimplePasswordProvider(password));
  }

  Future<void> _init() async {
    if (!_initialized) {
      await pdfrxFlutterInitialize();
      _initialized = true;
    }
  }
}

/// Images → PDF: the paper. [fit] makes each page exactly its image's size.
/// Sizes are in PDF points (1/72 inch).
enum PdfPaperSize {
  fit(null, null),
  a4(595.28, 841.89),
  letter(612, 792);

  new(this.width, this.height);

  /// Portrait width and height; null for [fit].
  final double? width;
  final double? height;
}

/// Images → PDF: [auto] turns each page to match its image.
enum PdfOrientation { auto, portrait, landscape }

/// Images → PDF: white space around each image, in points.
enum PdfMargin {
  none(0),
  small(18),
  large(36);

  new(this.points);

  final double points;
}

/// Compress PDF: pages are redrawn as JPEGs at [dpi] and [quality].
enum PdfCompressLevel {
  light(150, 80),
  medium(120, 65),
  strong(96, 50);

  new(this.dpi, this.quality);

  final int dpi;
  final int quality;
}

/// PDF → Images: the output's sharpness.
enum PdfRenderDpi {
  screen(96),
  standard(150),
  print(300);

  new(this.dpi);

  final int dpi;
}

part of 'tool_options_notifier.dart';

/// Every tool's options (each tool reads its own) and the request they make
/// with the picked files, or why there's none yet ([problem]).
final class const ToolOptionsState({
  // Images to PDF.
  final PdfPaperSize paper = .a4,
  final PdfOrientation orientation = .auto,
  final PdfMargin margin = .small,
  // PDF to images.
  final ConvertFormat imageFormat = .jpg,
  final PdfRenderDpi dpi = .standard,
  // Split.
  final SplitMode splitMode = .each,
  final int pagesPerPart = 2,
  final String ranges = '',
  // Organize pages: the pages to keep, in order, with their turns.
  final List<PdfPageRef> pages = const [],
  // Compress PDF.
  final PdfCompressLevel compressLevel = .medium,
  // Unlock PDF.
  final String password = '',
  // Video to GIF and Trim: the part, in seconds.
  final double start = 0,
  final double end = 0,
  final int fps = 12,
  final int gifWidth = 480,
  final bool exactCut = false,
  // Images to GIF.
  final double secondsPerImage = 1,
  // Resize: percent of the original size.
  final int scalePercent = 200,
  // Rotate & crop.
  final int quarterTurns = 0,
  final bool flipHorizontal = false,
  final bool flipVertical = false,
  final CropAspect cropAspect = .original,
  // Resize and Rotate & crop.
  final ConvertFormat outputFormat = .jpg,

  /// What the start button runs; null until the picks and options make sense.
  final ToolRequest? request,

  /// Why there's no [request] when the user can fix it (shown under the options).
  final String? problem,

  /// Split: how many PDFs the current options make.
  final int partCount = 0,
  super.status,
  super.message,
}) extends BaseState {
  ToolOptionsState copyWith({
    PdfPaperSize? paper,
    PdfOrientation? orientation,
    PdfMargin? margin,
    ConvertFormat? imageFormat,
    PdfRenderDpi? dpi,
    SplitMode? splitMode,
    int? pagesPerPart,
    String? ranges,
    List<PdfPageRef>? pages,
    PdfCompressLevel? compressLevel,
    String? password,
    double? start,
    double? end,
    int? fps,
    int? gifWidth,
    bool? exactCut,
    double? secondsPerImage,
    int? scalePercent,
    int? quarterTurns,
    bool? flipHorizontal,
    bool? flipVertical,
    CropAspect? cropAspect,
    ConvertFormat? outputFormat,
    StateMessage? message,
  }) => ToolOptionsState(
    paper: paper ?? this.paper,
    orientation: orientation ?? this.orientation,
    margin: margin ?? this.margin,
    imageFormat: imageFormat ?? this.imageFormat,
    dpi: dpi ?? this.dpi,
    splitMode: splitMode ?? this.splitMode,
    pagesPerPart: pagesPerPart ?? this.pagesPerPart,
    ranges: ranges ?? this.ranges,
    pages: pages ?? this.pages,
    compressLevel: compressLevel ?? this.compressLevel,
    password: password ?? this.password,
    start: start ?? this.start,
    end: end ?? this.end,
    fps: fps ?? this.fps,
    gifWidth: gifWidth ?? this.gifWidth,
    exactCut: exactCut ?? this.exactCut,
    secondsPerImage: secondsPerImage ?? this.secondsPerImage,
    scalePercent: scalePercent ?? this.scalePercent,
    quarterTurns: quarterTurns ?? this.quarterTurns,
    flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    flipVertical: flipVertical ?? this.flipVertical,
    cropAspect: cropAspect ?? this.cropAspect,
    outputFormat: outputFormat ?? this.outputFormat,
    request: request,
    problem: problem,
    partCount: partCount,
    status: status,
    message: message,
  );

  /// The same options with a new [request], [problem] and [partCount].
  ToolOptionsState withRequest(ToolRequest? request, {String? problem, int partCount = 0}) => ToolOptionsState(
    paper: paper,
    orientation: orientation,
    margin: margin,
    imageFormat: imageFormat,
    dpi: dpi,
    splitMode: splitMode,
    pagesPerPart: pagesPerPart,
    ranges: ranges,
    pages: pages,
    compressLevel: compressLevel,
    password: password,
    start: start,
    end: end,
    fps: fps,
    gifWidth: gifWidth,
    exactCut: exactCut,
    secondsPerImage: secondsPerImage,
    scalePercent: scalePercent,
    quarterTurns: quarterTurns,
    flipHorizontal: flipHorizontal,
    flipVertical: flipVertical,
    cropAspect: cropAspect,
    outputFormat: outputFormat,
    request: request,
    problem: problem,
    partCount: partCount,
    status: status,
    message: message,
  );

  @override
  List<Object?> get props => [
    paper,
    orientation,
    margin,
    imageFormat,
    dpi,
    splitMode,
    pagesPerPart,
    ranges,
    pages,
    compressLevel,
    password,
    start,
    end,
    fps,
    gifWidth,
    exactCut,
    secondsPerImage,
    scalePercent,
    quarterTurns,
    flipHorizontal,
    flipVertical,
    cropAspect,
    outputFormat,
    request,
    problem,
    partCount,
    ...super.props,
  ];
}

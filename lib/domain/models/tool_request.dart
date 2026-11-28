import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/convert_format.dart';
import 'package:media_tool/domain/models/crop_rect.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/pdf_layout.dart';
import 'package:media_tool/domain/models/video_clip.dart';

/// One run of a tool from the Tools tab. PDF tools run on PDFium (pdfrx) and
/// the `pdf` package; GIF, video and image tools run ffmpeg.
/// See docs/features/tools.md.
sealed class const ToolRequest() extends Equatable {
  /// The picked inputs, in the user's order.
  List<LocalMediaInfo> get sources;

  /// What the outputs are.
  MediaKind get outputKind;

  /// Whether the run uses ffmpeg (and so waits for the shared ffmpeg slot).
  bool get usesFfmpeg => this is MediaToolRequest;
}

sealed class const PdfToolRequest() extends ToolRequest {
  @override
  MediaKind get outputKind => .document;
}

sealed class const MediaToolRequest() extends ToolRequest;

/// Images → one PDF, a page per image.
final class const ImagesToPdfRequest({
  @override required final List<LocalMediaInfo> sources,
  final PdfPaperSize paper = .a4,
  final PdfOrientation orientation = .auto,
  final PdfMargin margin = .small,
}) extends PdfToolRequest {
  @override
  List<Object?> get props => [sources, paper, orientation, margin];
}

/// A PDF → one image per page.
final class const PdfToImagesRequest({
  required final LocalMediaInfo source,
  final ConvertFormat format = .jpg,
  final PdfRenderDpi dpi = .standard,
}) extends PdfToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .photo;

  @override
  List<Object?> get props => [source, format, dpi];
}

/// Several PDFs → one, in order.
final class const MergePdfRequest({@override required final List<LocalMediaInfo> sources}) extends PdfToolRequest {
  @override
  List<Object?> get props => [sources];
}

/// A PDF → one PDF per group of pages ([groups] hold 0-based page indexes).
final class const SplitPdfRequest({required final LocalMediaInfo source, required final List<List<int>> groups})
    extends PdfToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  List<Object?> get props => [source, groups];
}

/// One page of an organised PDF: its 0-based index in the source and the
/// clockwise quarter turns added to it.
final class const PdfPageRef({required final int index, final int quarterTurns = 0}) extends Equatable {
  PdfPageRef rotated() => PdfPageRef(index: index, quarterTurns: (quarterTurns + 1) % 4);

  @override
  List<Object?> get props => [index, quarterTurns];
}

/// A PDF with its pages reordered, rotated or removed.
final class const OrganizePdfRequest({required final LocalMediaInfo source, required final List<PdfPageRef> pages})
    extends PdfToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  List<Object?> get props => [source, pages];
}

/// A PDF redrawn as JPEG pages: much smaller for scans, but text can no
/// longer be selected.
final class const CompressPdfRequest({required final LocalMediaInfo source, final PdfCompressLevel level = .medium})
    extends PdfToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  List<Object?> get props => [source, level];
}

/// A password-protected PDF saved without its password.
final class const UnlockPdfRequest({required final LocalMediaInfo source, required final String password})
    extends PdfToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  List<Object?> get props => [source, password];
}

/// A part of a video ([startSeconds]–[endSeconds]) → an animated GIF.
final class const VideoToGifRequest({
  required final LocalMediaInfo source,
  required final double startSeconds,
  required final double endSeconds,
  final int fps = 12,
  final int width = 480,
}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .photo;

  double get durationSeconds => endSeconds - startSeconds;

  @override
  List<Object?> get props => [source, startSeconds, endSeconds, fps, width];
}

/// Images → an animated GIF, [secondsPerImage] each, on a canvas [width]
/// wide shaped like the first image.
final class const ImagesToGifRequest({
  @override required final List<LocalMediaInfo> sources,
  final double secondsPerImage = 1,
  final int width = 480,
}) extends MediaToolRequest {
  @override
  MediaKind get outputKind => .photo;

  @override
  List<Object?> get props => [sources, secondsPerImage, width];
}

/// An animated GIF → an MP4 that plays everywhere.
final class const GifToVideoRequest({required final LocalMediaInfo source}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .video;

  @override
  List<Object?> get props => [source];
}

/// Keep the [clips] of a video ([mode] keep), or cut them out and keep the
/// rest ([mode] remove). [clips] are sorted and merged ([VideoClip.merged]).
/// Several kept parts are joined into one video (re-encoded, frame-exact),
/// or saved one file each when [separate] (keep mode). A single part, or
/// separate parts, are stream-copied (fast, cuts on keyframes) unless [exact].
final class const TrimVideoRequest({
  required final LocalMediaInfo source,
  required final List<VideoClip> clips,
  final TrimMode mode = .keep,
  final bool separate = false,
  final bool exact = false,
}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .video;

  /// The parts of the source that end up in the output, in order.
  List<VideoClip> get parts => switch (mode) {
    .keep => clips,
    .remove => VideoClip.outside(clips, source.durationSeconds ?? 0),
  };

  /// Several parts joined into one video: always re-encoded.
  bool get joins => parts.length > 1 && !(mode == .keep && separate);

  /// Streams are copied instead of re-encoded.
  bool get copies => !exact && !joins;

  /// The length of everything kept, in seconds.
  double get keptSeconds => parts.fold(0, (total, part) => total + part.length);

  @override
  List<Object?> get props => [source, clips, mode, separate, exact];
}

/// A video without its sound (streams copied).
final class const MuteVideoRequest({required final LocalMediaInfo source}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .video;

  @override
  List<Object?> get props => [source];
}

/// An image scaled to exactly [width] × [height] (up with Lanczos and a light
/// sharpen, or down), saved as [format].
final class const ResizeImageRequest({
  required final LocalMediaInfo source,
  required final int width,
  required final int height,
  final ConvertFormat format = .jpg,
  final int quality = 92,
}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .photo;

  bool get upscales => (source.width ?? width) < width;

  @override
  List<Object?> get props => [source, width, height, format, quality];
}

/// An image cropped ([crop], before the turn), turned [quarterTurns]
/// clockwise and flipped, saved as [format].
final class const EditImageRequest({
  required final LocalMediaInfo source,
  final CropRect? crop,
  final int quarterTurns = 0,
  final bool flipHorizontal = false,
  final bool flipVertical = false,
  final ConvertFormat format = .jpg,
}) extends MediaToolRequest {
  @override
  List<LocalMediaInfo> get sources => [source];

  @override
  MediaKind get outputKind => .photo;

  bool get changesNothing => crop == null && quarterTurns == 0 && !flipHorizontal && !flipVertical;

  @override
  List<Object?> get props => [source, crop, quarterTurns, flipHorizontal, flipVertical, format];
}

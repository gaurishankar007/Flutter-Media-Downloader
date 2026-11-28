import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/media_kind.dart';

/// A local file picked for conversion or a tool, as ffmpeg, the image decoder
/// or PDFium read it.
final class const LocalMediaInfo({
  /// Absolute path of the file to read: a working copy, or the Library file itself.
  required final String path,
  required final String title,
  required final MediaKind kind,

  /// Lower-case extension: mp4, mkv, jpg…
  required final String format,
  required final int sizeBytes,

  /// The Library item it came from (its file is never changed).
  final String? libraryItemId,
  final String? thumbnailPath,
  final double? durationSeconds,

  /// Display size (rotation applied).
  final int? width,
  final int? height,
  final String? videoCodec,
  final String? audioCodec,
  final int? audioKbps,

  /// PDFs: the number of pages (null while [encrypted]).
  final int? pageCount,

  /// PDFs: opening it needs a password.
  final bool encrypted = false,
}) extends Equatable {
  bool get hasAudio => audioCodec != null;

  /// The short side (the "p" in 1080p), or null when unknown.
  int? get shortSide => width == null || height == null ? null : (width! < height! ? width : height);

  int? get longSide => width == null || height == null ? null : (width! > height! ? width : height);

  bool get isPortrait => width != null && height != null && height! > width!;

  /// H.264 / HEVC: plays on iPhone and can be copied into MP4 / MOV as is.
  bool get hasIphoneVideo => videoCodec == 'h264' || videoCodec == 'hevc';

  bool get hasAacAudio => audioCodec == 'aac';

  @override
  List<Object?> get props => [
    path,
    title,
    kind,
    format,
    sizeBytes,
    libraryItemId,
    thumbnailPath,
    durationSeconds,
    width,
    height,
    videoCodec,
    audioCodec,
    audioKbps,
    pageCount,
    encrypted,
  ];
}

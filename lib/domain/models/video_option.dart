import 'package:equatable/equatable.dart';

/// One video quality a link offers. See docs/engine/media_engine.md#probe.
final class const VideoOption({
  /// Height cap in pixels passed to yt-dlp; `null` is Best (no cap).
  final int? height,

  /// The label's number: the short side (1080 for a 1920×1080 or a
  /// 1080×1920 vertical video), so vertical videos read as "1080p" too.
  final int? resolution,

  /// Estimated size of video + audio, when the site reports it.
  final int? sizeBytes,

  /// H.264 exists at this height, so an iPhone-compatible MP4 needs only a
  /// remux. When false, iPhone-compatible output means a slow re-encode.
  final bool hasH264 = false,
}) extends Equatable {
  @override
  List<Object?> get props => [height, resolution, sizeBytes, hasH264];
}

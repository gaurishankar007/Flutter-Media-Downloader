import 'package:equatable/equatable.dart';
import 'package:media_downloader/domain/models/post_media.dart';
import 'package:media_downloader/domain/models/preview_stream.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/domain/models/video_option.dart';

/// What a probe found behind a link.
final class const MediaInfo({
  required final String url,
  required final Site site,
  required final String title,
  final String? uploader,
  final int? durationSeconds,
  final String? thumbnailUrl,

  /// Best first, then by height descending. Empty when there's no video.
  final List<VideoOption> videoOptions = const [],
  final bool hasAudio = true,

  /// Approximate audio bitrate of the best audio stream, for size estimates.
  final double? audioKbps,

  /// Played inline in the preview; null shows the thumbnail only.
  final PreviewStream? previewStream,

  /// The post's own id (shortcode, status id), used in photo filenames.
  final String? postId,

  /// Photos (and a carousel's videos) found by a photo extractor, in order.
  /// Downloaded directly, without the engine.
  final List<PostMedia> postMedia = const [],

  /// TikTok slideshows: the post's music, for "Save as video".
  final String? musicUrl,
}) extends Equatable {
  /// The engine found a video (quality options apply).
  bool get hasVideo => videoOptions.isNotEmpty;

  /// A photo extractor found the post's items (the Photos choice).
  bool get hasPostMedia => postMedia.isNotEmpty;

  bool get hasPhotos => postMedia.any((media) => media.kind == .photo);

  /// A copy with a photo extractor's findings added to an engine probe.
  MediaInfo withPost(MediaInfo post) => MediaInfo(
    url: url,
    site: site,
    title: title,
    uploader: uploader ?? post.uploader,
    durationSeconds: durationSeconds,
    thumbnailUrl: thumbnailUrl ?? post.thumbnailUrl,
    videoOptions: videoOptions,
    hasAudio: hasAudio,
    audioKbps: audioKbps,
    previewStream: previewStream,
    postId: postId ?? post.postId,
    postMedia: post.postMedia,
    musicUrl: musicUrl ?? post.musicUrl,
  );

  @override
  List<Object?> get props => [
    url,
    site,
    title,
    uploader,
    durationSeconds,
    thumbnailUrl,
    videoOptions,
    hasAudio,
    audioKbps,
    previewStream,
    postId,
    postMedia,
    musicUrl,
  ];
}

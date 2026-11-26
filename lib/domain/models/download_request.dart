import 'package:equatable/equatable.dart';
import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/audio_quality.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/domain/models/post_media.dart';
import 'package:media_downloader/domain/models/site.dart';

/// Everything needed to run (or retry) one download. Stored as JSON on the job.
final class const DownloadRequest({
  required final String url,
  required final Site site,
  required final String title,
  required final MediaKind kind,
  final String? uploader,
  final String? thumbnailUrl,
  final int? durationSeconds,

  /// Video height cap; `null` is Best.
  final int? height,

  /// The quality's label number (1080 for "1080p"), used in the filename.
  final int? resolution,
  final AudioQuality audioQuality = .kbps320,
  final bool iphoneCompatible = true,

  /// Whether iPhone-compatible output needs an ffmpeg re-encode after download.
  final bool needsReencode = false,
  final int? expectedBytes,

  /// Photo posts: the chosen items, downloaded directly instead of by the
  /// engine. See docs/extractors/photo_extractors.md#downloading-the-images.
  final List<PostMedia> media = const [],
  final String? postId,

  /// Convert WebP / HEIC photos to JPG (Settings → Downloads).
  final bool photosToJpg = true,

  /// TikTok slideshows: join the photos and [musicUrl] into one MP4.
  final bool slideshowVideo = false,
  final String? musicUrl,
}) extends Equatable {
  factory fromJson(JsonMap json) => DownloadRequest(
    url: json['url'] as String,
    site: Site.values.byName(json['site'] as String),
    title: json['title'] as String,
    kind: MediaKind.values.byName(json['kind'] as String),
    uploader: json['uploader'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    durationSeconds: json['durationSeconds'] as int?,
    height: json['height'] as int?,
    resolution: json['resolution'] as int?,
    audioQuality: AudioQuality.values.asNameMap()[json['audioQuality']] ?? .kbps320,
    iphoneCompatible: json['iphoneCompatible'] != false,
    needsReencode: json['needsReencode'] == true,
    expectedBytes: json['expectedBytes'] as int?,
    media: [for (final item in json['media'] as List<dynamic>? ?? const []) PostMedia.fromJson(item as JsonMap)],
    postId: json['postId'] as String?,
    photosToJpg: json['photosToJpg'] != false,
    slideshowVideo: json['slideshowVideo'] == true,
    musicUrl: json['musicUrl'] as String?,
  );

  /// Downloaded directly from the post's media URLs, not by the engine.
  bool get isPost => media.isNotEmpty;

  JsonMap toJson() => {
    'url': url,
    'site': site.name,
    'title': title,
    'kind': kind.name,
    'uploader': uploader,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
    'height': height,
    'resolution': resolution,
    'audioQuality': audioQuality.name,
    'iphoneCompatible': iphoneCompatible,
    'needsReencode': needsReencode,
    'expectedBytes': expectedBytes,
    'media': [for (final item in media) item.toJson()],
    'postId': postId,
    'photosToJpg': photosToJpg,
    'slideshowVideo': slideshowVideo,
    'musicUrl': musicUrl,
  };

  @override
  List<Object?> get props => [
    url,
    site,
    title,
    kind,
    uploader,
    thumbnailUrl,
    durationSeconds,
    height,
    resolution,
    audioQuality,
    iphoneCompatible,
    needsReencode,
    expectedBytes,
    media,
    postId,
    photosToJpg,
    slideshowVideo,
    musicUrl,
  ];
}

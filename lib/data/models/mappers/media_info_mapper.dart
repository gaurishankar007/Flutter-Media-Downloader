import 'package:media_tool/data/models/responses/probe_response_dto.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/preview_stream.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/models/video_option.dart';

/// `yt-dlp -J` → [MediaInfo]: quality tiers with size estimates and whether
/// an iPhone-compatible file needs a re-encode. See docs/engine/media_engine.md#probe.
abstract final class MediaInfoMapper {
  static const _tiers = [2160, 1440, 1080, 720, 480, 360];
  static const _maxPreviewResolution = 720;

  static MediaInfo fromDto(ProbeResponseDto dto, {required String url, required Site site}) {
    final duration = dto.duration;
    final videos = dto.formats.where((format) => format.hasVideo).toList();
    final audios = dto.formats.where((format) => format.isAudioOnly).toList();
    final bestAudio = audios.isEmpty
        ? null
        : audios.reduce((a, b) => (a.abr ?? a.tbr ?? 0) >= (b.abr ?? b.tbr ?? 0) ? a : b);
    final audioBytes = bestAudio?.sizeFor(duration) ?? 0;

    final options = <VideoOption>[];
    for (final tier in _tiers) {
      // Formats whose short side rounds into this tier (e.g. 1080 for 1080–1439).
      final upper = _tiers.indexOf(tier) == 0 ? 1 << 30 : _tiers[_tiers.indexOf(tier) - 1];
      final inTier = videos.where((f) => (f.resolution ?? 0) >= tier && (f.resolution ?? 0) < upper).toList();
      if (inTier.isEmpty) {
        continue;
      }
      final best = inTier.reduce((a, b) => (a.tbr ?? 0) >= (b.tbr ?? 0) ? a : b);
      final videoBytes = best.sizeFor(duration);
      options.add(
        VideoOption(
          height: inTier.map((f) => f.height!).reduce((a, b) => a > b ? a : b),
          resolution: tier,
          sizeBytes: videoBytes == null ? null : videoBytes + (best.hasAudio ? 0 : audioBytes),
          hasH264: inTier.any((f) => f.isH264),
        ),
      );
    }
    // Small clips below 360p still get one option.
    if (options.isEmpty && videos.isNotEmpty) {
      final best = videos.reduce((a, b) => (a.height ?? 0) >= (b.height ?? 0) ? a : b);
      options.add(VideoOption(height: best.height, resolution: best.resolution, hasH264: best.isH264));
    }
    if (options.isNotEmpty) {
      final top = options.first;
      options.insert(0, VideoOption(sizeBytes: top.sizeBytes, hasH264: top.hasH264, resolution: top.resolution));
    }

    return MediaInfo(
      url: url,
      site: site,
      title: dto.title.trim().isEmpty ? site.label : dto.title.trim(),
      uploader: dto.uploader,
      durationSeconds: duration?.round(),
      thumbnailUrl: dto.thumbnail,
      videoOptions: options,
      hasAudio: dto.formats.any((format) => format.hasAudio) || dto.formats.isEmpty,
      audioKbps: bestAudio?.abr ?? bestAudio?.tbr,
      previewStream: _previewStream(dto.formats),
    );
  }

  /// The best progressive format up to 720p.
  static PreviewStream? _previewStream(List<FormatDto> formats) {
    final candidates = formats
        .where((format) => format.isProgressive && (format.resolution ?? 0) <= _maxPreviewResolution)
        .toList();
    if (candidates.isEmpty) {
      return null;
    }
    final best = candidates.reduce((a, b) => (a.resolution ?? 0) >= (b.resolution ?? 0) ? a : b);
    return PreviewStream(url: best.url!, headers: best.httpHeaders);
  }
}

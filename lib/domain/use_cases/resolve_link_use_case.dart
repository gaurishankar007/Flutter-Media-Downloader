import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/core/utils/url_utils.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/repositories/media_repository.dart';
import 'package:media_tool/domain/repositories/post_repository.dart';

/// Decides whether a pasted link is a video (engine probe) or a photo post
/// (Dart extractor), and returns what the preview shows.
/// See docs/extractors/photo_extractors.md#routing-a-link.
@injectable
final class ResolveLinkUseCase({required final MediaRepository _media, required final PostRepository _posts}) {
  /// Whether links from [site] can still be read when the engine isn't
  /// available (photo posts, Threads).
  bool worksWithoutEngine(Site site) => _posts.supports(site);

  /// [useEngine] false skips the probe (engine failed or missing) and asks
  /// the photo extractor only.
  FutureData<MediaInfo> run(String link, {bool useEngine = true}) async {
    final pasted = UrlUtils.extractUrl(link);
    if (pasted == null) {
      return const FailureState(message: DownloadMessages.notALink);
    }
    var url = UrlUtils.normalise(pasted);
    if (UrlUtils.isShortLink(url)) {
      // When following fails, the engine can still follow the short link itself.
      if (await _posts.followShortLink(url) case SuccessState(:final data?)) {
        url = UrlUtils.normalise(data);
      }
    }
    final site = UrlUtils.detectSite(url);
    if (site == null) {
      return const FailureState(message: DownloadMessages.unsupportedLink);
    }

    if (site == .threads || UrlUtils.looksLikePhotoPost(url) || !useEngine) {
      return await _posts.extract(url, site);
    }

    final probe = await _media.probe('$url', site);
    if (probe case SuccessState(:final data?)) {
      return SuccessState(data: await _withPhotos(data, url, site));
    }
    if (!_posts.supports(site)) {
      return probe;
    }
    // The engine says "no video" for photo posts (Instagram /p/, X images).
    final post = await _posts.extract(url, site);
    if (post case SuccessState(data: _?)) {
      return post;
    }
    return probe.message == EngineMessages.noVideo ? post : probe;
  }

  /// Mixed posts (an Instagram carousel or a tweet with a video and photos):
  /// adds the photos as a Photos choice next to Video / Audio.
  Future<MediaInfo> _withPhotos(MediaInfo info, Uri url, Site site) async {
    final mixable = (site == .instagram && url.path.contains('/p/')) || site == .x;
    if (!mixable) {
      return info;
    }
    final post = await _posts.extract(url, site);
    return switch (post) {
      SuccessState(:final data?) when data.hasPhotos => info.withPost(data),
      _ => info,
    };
  }
}

import 'package:injectable/injectable.dart';
import 'package:media_tool/data/services/remote/extractors/facebook_photo_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/instagram_photo_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/photo_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/threads_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/tiktok_photo_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/x_image_extractor.dart';
import 'package:media_tool/data/services/remote/extractors/youtube_post_extractor.dart';
import 'package:media_tool/domain/models/site.dart';

/// Every photo extractor, looked up by site and link.
@lazySingleton
final class PhotoExtractors({
  required final InstagramPhotoExtractor _instagram,
  required final TikTokPhotoExtractor _tiktok,
  required final FacebookPhotoExtractor _facebook,
  required final ThreadsExtractor _threads,
  required final XImageExtractor _x,
  required final YouTubePostExtractor _youtube,
}) {
  List<PhotoExtractor> get _all => [_instagram, _tiktok, _facebook, _threads, _x, _youtube];

  /// Whether any extractor reads [site].
  bool supports(Site site) => _all.any((extractor) => extractor.site == site);

  PhotoExtractor? forUrl(Uri url, Site site) =>
      _all.where((extractor) => extractor.site == site && extractor.canHandle(url)).firstOrNull;
}

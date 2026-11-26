import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/download_event.dart';
import 'package:media_downloader/domain/models/download_job.dart';
import 'package:media_downloader/domain/models/media_info.dart';
import 'package:media_downloader/domain/models/site.dart';

/// Photo posts (and Threads): reading them with the Dart extractors and
/// downloading their files directly. See docs/extractors/photo_extractors.md.
abstract interface class PostRepository {
  /// Whether a photo extractor reads [site].
  bool supports(Site site);

  /// Where a short link (`vm.tiktok.com`, `fb.watch`, `t.co`) leads.
  FutureData<Uri> followShortLink(Uri url);

  /// The post's photos / videos as a [MediaInfo] with `postMedia` filled.
  FutureData<MediaInfo> extract(Uri url, Site site);

  /// Downloads the job's chosen items (and a slideshow's music) into its work
  /// folder; ends with [PostDownloadFinished].
  Stream<DownloadEvent> download(DownloadJob job);

  /// Re-encodes every photo in [paths] that isn't a JPG; videos and JPGs pass
  /// through. Returns the paths in the same order.
  FutureList<String> convertPhotosToJpg(List<String> paths);

  Future<void> cancel(String jobId);
}

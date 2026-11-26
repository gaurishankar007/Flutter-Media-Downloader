import 'package:media_downloader/data/models/responses/extracted_post_dto.dart';
import 'package:media_downloader/domain/models/site.dart';

/// Reads one site's photo posts with plain HTTP + HTML/JSON parsing, so it
/// works the same on every platform. Throws `ExtractorException` or
/// `DioException`. Each site is one isolated file, easy to fix when the site
/// changes. See docs/extractors/photo_extractors.md.
abstract interface class PhotoExtractor {
  Site get site;

  bool canHandle(Uri url);

  /// [cookiesPath] is set when the user imported cookies for [site]; the HTTP
  /// client sends them to [site]'s own hosts only.
  Future<ExtractedPostDto> extract(Uri url, {String? cookiesPath});
}

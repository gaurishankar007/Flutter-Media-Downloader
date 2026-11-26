import 'package:injectable/injectable.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/domain/models/download_event.dart';
import 'package:media_downloader/domain/models/download_job.dart';
import 'package:media_downloader/domain/models/job_progress.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/domain/models/post_file.dart';
import 'package:media_downloader/domain/repositories/library_repository.dart';
import 'package:media_downloader/domain/repositories/media_repository.dart';
import 'package:media_downloader/domain/repositories/post_repository.dart';
import 'package:path/path.dart' as p;

/// Runs one download end to end. Videos / audio: engine download → iPhone
/// re-encode when needed → move into the Library. Photo posts: direct
/// download → JPG (or slideshow video) → Library rows sharing a group. Every
/// step reports a [JobProgress]; the last one is done, failed or cancelled.
/// See docs/features/download.md.
@injectable
final class DownloadMediaUseCase({
  required final MediaRepository _media,
  required final LibraryRepository _library,
  required final PostRepository _posts,
}) {
  Stream<JobProgress> run(DownloadJob job) async* {
    try {
      yield* job.request.isPost ? _runPost(job) : _runEngine(job);
    } finally {
      await _media.clearWork(job.id);
    }
  }

  Future<void> cancel(String jobId) async {
    await _posts.cancel(jobId);
    await _media.cancel(jobId);
  }

  Stream<JobProgress> _runEngine(DownloadJob job) async* {
    String? mediaPath;
    String? thumbnailPath;

    await for (final event in _media.download(job)) {
      switch (event) {
        case DownloadProgressed(:final progress):
          yield progress;
        case DownloadFinished(mediaPath: final media, thumbnailPath: final thumbnail):
          mediaPath = media;
          thumbnailPath = thumbnail;
        case DownloadFailed(:final message):
          yield JobProgress(stage: .failed, errorMessage: message);
          return;
        case DownloadCancelled():
          yield const JobProgress(stage: .cancelled);
          return;
        case PostDownloadFinished():
          break;
      }
    }
    if (mediaPath == null) {
      return;
    }

    final request = job.request;
    if (request.kind == MediaKind.video && request.iphoneCompatible && request.needsReencode) {
      yield const JobProgress(stage: .processing, step: .convertingForIphone);
      String? converted;
      await for (final event in _media.convertForIphone(job, mediaPath)) {
        switch (event) {
          case DownloadProgressed(:final progress):
            yield progress;
          case DownloadFinished(mediaPath: final media):
            converted = media;
          case DownloadFailed(:final message):
            yield JobProgress(stage: .failed, errorMessage: message);
            return;
          case DownloadCancelled():
            yield const JobProgress(stage: .cancelled);
            return;
          case PostDownloadFinished():
            break;
        }
      }
      if (converted == null) {
        return;
      }
      mediaPath = converted;
    }

    yield const JobProgress(stage: .saving);
    final added = await _library.addDownload(request, mediaPath: mediaPath, thumbnailPath: thumbnailPath);
    yield switch (added) {
      SuccessState(:final data?) => JobProgress(stage: .done, libraryItemIds: [data.id], sizeBytes: data.sizeBytes),
      _ => JobProgress(stage: .failed, errorMessage: added.message),
    };
  }

  /// A photo post (or Threads / carousel videos), downloaded directly.
  /// See docs/extractors/photo_extractors.md#downloading-the-images.
  Stream<JobProgress> _runPost(DownloadJob job) async* {
    final request = job.request;
    PostDownloadFinished? downloaded;
    await for (final event in _posts.download(job)) {
      switch (event) {
        case DownloadProgressed(:final progress):
          yield progress;
        case final PostDownloadFinished finished:
          downloaded = finished;
        case DownloadFailed(:final message):
          yield JobProgress(stage: .failed, errorMessage: message);
          return;
        case DownloadCancelled():
          yield const JobProgress(stage: .cancelled);
          return;
        case DownloadFinished():
          break;
      }
    }
    if (downloaded == null) {
      return;
    }

    if (request.slideshowVideo && downloaded.musicPath != null) {
      yield* _slideshow(job, downloaded.paths, downloaded.musicPath!);
      return;
    }

    var paths = downloaded.paths;
    if (request.photosToJpg) {
      yield const JobProgress(stage: .processing, step: .convertingPhotos);
      final converted = await _posts.convertPhotosToJpg(paths);
      switch (converted) {
        case SuccessState(:final data?):
          paths = data;
        default:
          yield JobProgress(stage: .failed, errorMessage: converted.message);
          return;
      }
    }

    yield const JobProgress(stage: .saving);
    final files = <PostFile>[
      for (final (index, path) in paths.indexed)
        (
          path: path,
          kind: request.media[index].kind,
          thumbnailPath: index < downloaded.thumbnailPaths.length ? downloaded.thumbnailPaths[index] : null,
        ),
    ];
    final added = await _library.addPost(request, files: files);
    yield switch (added) {
      SuccessState(:final data?) => JobProgress(
        stage: .done,
        libraryItemIds: [for (final item in data) item.id],
        sizeBytes: data.fold<int>(0, (sum, item) => sum + item.sizeBytes),
      ),
      _ => JobProgress(stage: .failed, errorMessage: added.message),
    };
  }

  /// TikTok "Save as video": the photos as JPGs plus the music, in one MP4.
  Stream<JobProgress> _slideshow(DownloadJob job, List<String> paths, String musicPath) async* {
    yield const JobProgress(stage: .processing, step: .makingSlideshow);
    final images = await _posts.convertPhotosToJpg(paths);
    final jpgs = images.data;
    if (images is! SuccessState || jpgs == null || jpgs.isEmpty) {
      yield JobProgress(stage: .failed, errorMessage: images.message);
      return;
    }

    String? video;
    await for (final event in _media.makeSlideshow(job, imageDir: p.dirname(jpgs.first), musicPath: musicPath)) {
      switch (event) {
        case DownloadProgressed(:final progress):
          yield progress;
        case DownloadFinished(:final mediaPath):
          video = mediaPath;
        case DownloadFailed(:final message):
          yield JobProgress(stage: .failed, errorMessage: message);
          return;
        case DownloadCancelled():
          yield const JobProgress(stage: .cancelled);
          return;
        case PostDownloadFinished():
          break;
      }
    }
    if (video == null) {
      return;
    }

    yield const JobProgress(stage: .saving);
    // The first photo becomes the video's thumbnail.
    final added = await _library.addDownload(job.request, mediaPath: video, thumbnailPath: jpgs.first);
    yield switch (added) {
      SuccessState(:final data?) => JobProgress(stage: .done, libraryItemIds: [data.id], sizeBytes: data.sizeBytes),
      _ => JobProgress(stage: .failed, errorMessage: added.message),
    };
  }
}

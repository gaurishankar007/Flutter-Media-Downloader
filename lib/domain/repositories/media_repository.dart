import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/download_event.dart';
import 'package:media_tool/domain/models/download_job.dart';
import 'package:media_tool/domain/models/engine_info.dart';
import 'package:media_tool/domain/models/engine_update.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/site.dart';

/// Talks to the download engine: probe, download, re-encode, cancel.
abstract interface class MediaRepository {
  FutureData<EngineInfo> initEngine();

  FutureData<MediaInfo> probe(String url, Site site);

  /// Downloads [job] into its work folder.
  Stream<DownloadEvent> download(DownloadJob job);

  /// Re-encodes [inputPath] to an iPhone-compatible MP4 in the work folder,
  /// trying the best available encoder first.
  Stream<DownloadEvent> convertForIphone(DownloadJob job, String inputPath);

  /// Joins a TikTok slideshow's JPGs (`01.jpg`, `02.jpg`… in [imageDir]) and
  /// [musicPath] into one MP4 in the work folder.
  Stream<DownloadEvent> makeSlideshow(DownloadJob job, {required String imageDir, required String musicPath});

  Future<void> cancel(String jobId);

  /// Updates yt-dlp; returns the version after the update.
  FutureData<String> updateEngine();

  /// Compares the running yt-dlp with the latest release.
  FutureData<EngineUpdate> checkForUpdate();

  /// Deletes [jobId]'s work folder.
  Future<void> clearWork(String jobId);
}

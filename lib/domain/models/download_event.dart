import 'package:media_downloader/domain/models/job_progress.dart';

/// One step of an engine run (download or re-encode) for the use case.
sealed class const DownloadEvent();

final class const DownloadProgressed(final JobProgress progress) extends DownloadEvent;

/// The run finished. [mediaPath] / [thumbnailPath] are in the job's work folder.
final class const DownloadFinished({required final String mediaPath, final String? thumbnailPath})
    extends DownloadEvent;

/// A post download finished. [paths] are in the job's work folder, in the
/// order of `DownloadRequest.media`; [thumbnailPaths] line up with them (the
/// still of a video, else null). [musicPath] is a slideshow's music.
final class const PostDownloadFinished({
  required final List<String> paths,
  final List<String?> thumbnailPaths = const [],
  final String? musicPath,
}) extends DownloadEvent;

final class const DownloadFailed(final String message) extends DownloadEvent;

final class const DownloadCancelled() extends DownloadEvent;

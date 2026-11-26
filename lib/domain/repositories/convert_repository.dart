import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/domain/models/convert_format.dart';
import 'package:media_downloader/domain/models/convert_request.dart';
import 'package:media_downloader/domain/models/download_event.dart';
import 'package:media_downloader/domain/models/library_item.dart';
import 'package:media_downloader/domain/models/local_media_info.dart';

/// The converter: reads local files, runs ffmpeg / the image encoders and
/// adds results to the Library. See docs/features/convert.md.
abstract interface class ConvertRepository {
  /// Asks for a video or photo from Photos / the gallery, copies it into
  /// `work/` and reads it. Data is null when the user cancels.
  FutureData<LocalMediaInfo?> pickFromPhotos();

  /// Same as [pickFromPhotos] with the system file picker.
  FutureData<LocalMediaInfo?> pickFromFiles();

  /// Copies a file dropped on the window into `work/` and reads it.
  FutureData<LocalMediaInfo> importFile(String path);

  /// Reads a Library item's file in place (it's never changed).
  FutureData<LocalMediaInfo> fromLibrary(String id);

  /// Deletes a picked file's working copy. Library files are left alone.
  Future<void> discard(LocalMediaInfo source);

  /// The formats [source] can be converted to on this device, best first.
  Future<List<ConvertFormat>> targetsFor(LocalMediaInfo source);

  /// What Compress writes for [source] (MP4 for video, the image's own
  /// format where it can be written, else JPG), or null when it can't be compressed (audio).
  ConvertFormat? compressFormatFor(LocalMediaInfo source);

  /// Runs [request] into [jobId]'s work folder. Waits for the shared ffmpeg
  /// slot first; ends with [DownloadFinished] (output + thumbnail), failed or cancelled.
  Stream<DownloadEvent> run(String jobId, ConvertRequest request);

  /// Moves the output into the Library (`origin: convert`) and adds its row.
  FutureData<LibraryItem> save(ConvertRequest request, {required String outputPath, String? thumbnailPath});

  Future<void> cancel(String jobId);

  /// Deletes [jobId]'s work folder.
  Future<void> clearWork(String jobId);
}

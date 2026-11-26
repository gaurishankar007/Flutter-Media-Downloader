import 'package:media_downloader/core/types/types.dart';
import 'package:media_downloader/data/models/responses/probe_response_dto.dart';
import 'package:media_downloader/data/services/platform/media_engine/engine_event.dart';
import 'package:media_downloader/domain/models/engine_info.dart';

/// yt-dlp and ffmpeg behind one interface; one implementation per platform.
/// Commands come from YtDlpArgsBuilder / FfmpegCommandBuilder; engines only
/// run them. See docs/engine/media_engine.md.
abstract interface class MediaEngine {
  /// Unpacks / prepares yt-dlp, Python and ffmpeg.
  FutureData<EngineInfo> init();

  /// Runs `yt-dlp -J` ([args] from `YtDlpArgsBuilder.probe`).
  FutureData<ProbeResponseDto> probe(List<String> args);

  /// Runs yt-dlp for [jobId]. The stream ends after its last event.
  Stream<EngineEvent> download(String jobId, List<String> args);

  /// Runs ffmpeg for [jobId]. The stream ends after its last event.
  Stream<EngineEvent> ffmpeg(String jobId, List<String> args);

  Future<void> cancel(String jobId);

  /// Updates yt-dlp in place and returns the version after the update.
  FutureData<String> updateYtDlp();
}

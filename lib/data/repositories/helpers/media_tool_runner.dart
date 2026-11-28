import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/file_service.dart';
import 'package:media_tool/data/repositories/helpers/local_media_reader.dart';
import 'package:media_tool/data/repositories/helpers/tool_runner_steps.dart';
import 'package:media_tool/data/services/platform/image_convert_service.dart';
import 'package:media_tool/data/services/platform/image_service.dart';
import 'package:media_tool/data/services/platform/media_engine/builders/ffmpeg_command_builder.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/ffmpeg_slot.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/data/services/platform/media_engine/parsers/ffmpeg_progress_parser.dart';
import 'package:media_tool/domain/models/job_progress.dart';
import 'package:media_tool/domain/models/local_media_info.dart';
import 'package:media_tool/domain/models/tool_event.dart';
import 'package:media_tool/domain/models/tool_output.dart';
import 'package:media_tool/domain/models/tool_request.dart';
import 'package:path/path.dart' as p;

/// Runs the GIF, video and image tools with ffmpeg, one at a time in the
/// shared [FfmpegSlot]. See docs/features/tools.md#gif-video-and-image-tools.
@lazySingleton
final class MediaToolRunner({
  required final MediaEngine _engine,
  required final FfmpegSlot _slot,
  required final LocalMediaReader _reader,
  required final ImageService _images,
  required final ImageConvertService _decoder,
  required final FileService _files,
  required final ErrorHandler _errorHandler,
}) with ToolRunnerSteps {
  // Images that may carry an EXIF rotation or that ffmpeg may not decode: made
  // into an upright JPG by the platform decoder first.
  static const _normalised = {'jpg', 'jpeg', 'heic', 'heif'};

  @override
  ErrorHandler get errorHandler => _errorHandler;

  Stream<ToolEvent> run(String jobId, MediaToolRequest request, String workDir) async* {
    yield const ToolProgressed(JobProgress(stage: .queued));
    final release = await _slot.acquire();
    try {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final engine = await _reader.ensureEngine();
      if (engine case FailureState(:final message)) {
        yield ToolFailed(message ?? ToolsMessages.failed);
        return;
      }
      yield const ToolProgressed(JobProgress(stage: .processing));
      yield* switch (request) {
        final VideoToGifRequest request => _videoToGif(jobId, request, workDir),
        final ImagesToGifRequest request => _imagesToGif(jobId, request, workDir),
        final GifToVideoRequest request => _gifToVideo(jobId, request, workDir),
        final TrimVideoRequest request => _trim(jobId, request, workDir),
        final MuteVideoRequest request => _mute(jobId, request, workDir),
        final ResizeImageRequest request => _resize(jobId, request, workDir),
        final EditImageRequest request => _edit(jobId, request, workDir),
      };
    } finally {
      release();
      finish(jobId);
    }
  }

  Stream<ToolEvent> _videoToGif(String jobId, VideoToGifRequest request, String workDir) async* {
    final output = p.join(workDir, 'output.gif');
    final args = FfmpegCommandBuilder.gifFromVideo(
      input: request.source.path,
      output: output,
      startSeconds: request.startSeconds,
      durationSeconds: request.durationSeconds,
      fps: request.fps,
      width: request.width,
    );
    await for (final event in _ffmpeg(jobId, [args], durationSeconds: request.durationSeconds)) {
      if (event is! ToolFinished) {
        yield event;
        if (event is! ToolProgressed) {
          return;
        }
      }
    }
    yield ToolFinished([await _gif(jobId, output, workDir)]);
  }

  Stream<ToolEvent> _imagesToGif(String jobId, ImagesToGifRequest request, String workDir) async* {
    final count = request.sources.length;
    final frames = p.join(workDir, 'frames');
    // ffmpeg writes into folders; it doesn't make them.
    await _files.createDir(frames);
    int? width;
    int? height;
    for (final (index, source) in request.sources.indexed) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final jpg = p.join(workDir, 'image-${index + 1}.jpg');
      final frame = p.join(frames, '${(index + 1).toString().padLeft(3, '0')}.png');
      final failed = await attempt('tools.imagesToGif.image', () async {
        await _images.toJpg(source.path, jpg, quality: 95);
        if (width == null || height == null) {
          // Every frame gets the first image's shape.
          final size = await _decoder.sizeOf(jpg);
          final aspect = size == null || size.width == 0 ? 1.0 : size.height / size.width;
          width = request.width;
          height = (request.width * aspect / 2).round() * 2;
        }
      }, fallback: ToolsMessages.imageUnreadable(source.title));
      if (failed != null) {
        yield ToolFailed(failed);
        return;
      }
      final args = FfmpegCommandBuilder.fitFrame(input: jpg, output: frame, width: width!, height: height!);
      await for (final event in _ffmpeg(jobId, [args])) {
        if (event is! ToolFinished && event is! ToolProgressed) {
          yield event;
          return;
        }
      }
      yield ToolRunnerSteps.progress((index + 1) / (count * 2));
    }
    final output = p.join(workDir, 'output.gif');
    final args = FfmpegCommandBuilder.gifFromFrames(
      framePattern: p.join(frames, '%03d.png'),
      output: output,
      secondsPerImage: request.secondsPerImage,
    );
    await for (final event in _ffmpeg(jobId, [args], durationSeconds: count * request.secondsPerImage, from: 0.5)) {
      if (event is! ToolFinished) {
        yield event;
        if (event is! ToolProgressed) {
          return;
        }
      }
    }
    yield ToolFinished([await _gif(jobId, output, workDir)]);
  }

  Stream<ToolEvent> _gifToVideo(String jobId, GifToVideoRequest request, String workDir) async* {
    final output = p.join(workDir, 'output.mp4');
    final commands = [
      for (final encoder in _encoders())
        FfmpegCommandBuilder.gifToVideo(input: request.source.path, output: output, encoder: encoder),
    ];
    yield* _video(jobId, commands, output, workDir, durationSeconds: request.source.durationSeconds);
  }

  Stream<ToolEvent> _trim(String jobId, TrimVideoRequest request, String workDir) async* {
    final source = request.source;
    final copy = !request.exact;
    final output = p.join(workDir, 'output.${copy ? _copyExtension(source) : 'mp4'}');
    List<String> trim([String? encoder]) => FfmpegCommandBuilder.trim(
      input: source.path,
      output: output,
      startSeconds: request.startSeconds,
      durationSeconds: request.durationSeconds,
      encoder: encoder,
    );
    final commands = copy ? [trim()] : [for (final encoder in _encoders()) trim(encoder)];
    yield* _video(jobId, commands, output, workDir, durationSeconds: request.durationSeconds);
  }

  Stream<ToolEvent> _mute(String jobId, MuteVideoRequest request, String workDir) async* {
    final source = request.source;
    final output = p.join(workDir, 'output.${_copyExtension(source)}');
    final args = FfmpegCommandBuilder.mute(input: source.path, output: output);
    yield* _video(jobId, [args], output, workDir, durationSeconds: source.durationSeconds);
  }

  Stream<ToolEvent> _resize(String jobId, ResizeImageRequest request, String workDir) async* {
    final input = await _upright(request.source, workDir);
    if (input == null) {
      yield ToolFailed(ToolsMessages.imageUnreadable(request.source.title));
      return;
    }
    final output = p.join(workDir, 'output.${request.format.extension}');
    final args = FfmpegCommandBuilder.editImage(
      input: input,
      output: output,
      format: request.format.extension,
      quality: request.quality,
      width: request.width,
      height: request.height,
      sharpen: request.upscales,
    );
    yield* _image(jobId, args, output, workDir);
  }

  Stream<ToolEvent> _edit(String jobId, EditImageRequest request, String workDir) async* {
    final input = await _upright(request.source, workDir);
    if (input == null) {
      yield ToolFailed(ToolsMessages.imageUnreadable(request.source.title));
      return;
    }
    String? crop;
    if (request.crop case final rect?) {
      final size = await _decoder.sizeOf(input);
      if (size == null) {
        yield ToolFailed(ToolsMessages.imageUnreadable(request.source.title));
        return;
      }
      final width = (rect.width * size.width).round().clamp(1, size.width);
      final height = (rect.height * size.height).round().clamp(1, size.height);
      final left = (rect.left * size.width).round().clamp(0, size.width - width);
      final top = (rect.top * size.height).round().clamp(0, size.height - height);
      crop = '$width:$height:$left:$top';
    }
    final output = p.join(workDir, 'output.${request.format.extension}');
    final args = FfmpegCommandBuilder.editImage(
      input: input,
      output: output,
      format: request.format.extension,
      crop: crop,
      quarterTurns: request.quarterTurns,
      flipHorizontal: request.flipHorizontal,
      flipVertical: request.flipVertical,
    );
    yield* _image(jobId, args, output, workDir);
  }

  /// Runs [commands] in turn until one works (each is a fallback for the one
  /// before). Yields progress mapped into [from]–1, then one terminal event:
  /// an empty [ToolFinished] on success, [ToolFailed] or [ToolCancelled].
  Stream<ToolEvent> _ffmpeg(
    String jobId,
    List<List<String>> commands, {
    double? durationSeconds,
    double from = 0,
  }) async* {
    var lastError = '';
    for (final args in commands) {
      if (isCancelled(jobId)) {
        yield const ToolCancelled();
        return;
      }
      final parser = FfmpegProgressParser(durationSeconds: durationSeconds);
      await for (final event in _engine.ffmpeg(jobId, args)) {
        switch (event) {
          case EngineLine(:final text):
            if (parser.parse(text) case final progress?) {
              yield ToolProgressed(
                JobProgress(
                  stage: .processing,
                  fraction: from + (progress.fraction ?? 0) * (1 - from),
                  etaSeconds: progress.etaSeconds,
                ),
              );
            }
          case EngineDone():
            yield const ToolFinished([]);
            return;
          case EngineFailed(:final output):
            lastError = output;
          case EngineCancelled():
            yield const ToolCancelled();
            return;
        }
      }
    }
    yield ToolFailed(lastError.contains('No space left') ? CommonMessages.noSpace : ToolsMessages.failed);
  }

  /// One video output from [commands], with a still for the Library card.
  Stream<ToolEvent> _video(
    String jobId,
    List<List<String>> commands,
    String output,
    String workDir, {
    double? durationSeconds,
  }) async* {
    await for (final event in _ffmpeg(jobId, commands, durationSeconds: durationSeconds)) {
      if (event is! ToolFinished) {
        yield event;
        if (event is! ToolProgressed) {
          return;
        }
      }
    }
    final thumbnail = await _reader.videoThumbnail(
      'thumb-$jobId',
      output,
      p.join(workDir, 'output-thumb.jpg'),
      durationSeconds,
    );
    yield ToolFinished([
      ToolOutput(
        path: output,
        kind: .video,
        thumbnailPath: thumbnail,
        durationMs: durationSeconds == null ? null : (durationSeconds * 1000).round(),
      ),
    ]);
  }

  /// One image output from [args], with a small thumbnail.
  Stream<ToolEvent> _image(String jobId, List<String> args, String output, String workDir) async* {
    await for (final event in _ffmpeg(jobId, [args])) {
      if (event is! ToolFinished && event is! ToolProgressed) {
        yield event;
        return;
      }
    }
    final thumbnail = p.join(workDir, 'output-thumb.jpg');
    final made = await attempt(
      'tools.image.thumbnail',
      () => _images.thumbnail(output, thumbnail),
      fallback: ToolsMessages.failed,
    );
    yield ToolFinished([ToolOutput(path: output, kind: .photo, thumbnailPath: made == null ? thumbnail : null)]);
  }

  /// A GIF output; its first frame is the Library card's still.
  Future<ToolOutput> _gif(String jobId, String output, String workDir) async {
    final thumbnail = await _reader.videoThumbnail('thumb-$jobId', output, p.join(workDir, 'output-thumb.jpg'), 0);
    return ToolOutput(path: output, kind: .photo, thumbnailPath: thumbnail);
  }

  /// [source] as a file ffmpeg reads upright: JPG and HEIC go through the
  /// platform decoder (applies EXIF rotation); others are used as they are.
  /// Null when the image can't be decoded.
  Future<String?> _upright(LocalMediaInfo source, String workDir) async {
    if (!_normalised.contains(source.format)) {
      return source.path;
    }
    final jpg = p.join(workDir, 'input.jpg');
    final failed = await attempt(
      'tools.image.normalise',
      () => _images.toJpg(source.path, jpg, quality: 100),
      fallback: ToolsMessages.failed,
    );
    return failed == null ? jpg : null;
  }

  /// Video encoders to try, best first; libx264 is the last resort.
  List<String> _encoders() => [...FfmpegCommandBuilder.iphoneEncoders(_reader.encoders), 'libx264'];

  /// The container a stream copy keeps (AVI and 3GP become MKV, which takes any codec).
  static String _copyExtension(LocalMediaInfo source) => switch (source.format) {
    'avi' || '3gp' => 'mkv',
    'm4v' => 'mp4',
    final format => format,
  };
}

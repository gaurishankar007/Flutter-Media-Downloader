import 'package:flutter/services.dart';
import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/engine_errors.dart';
import 'package:media_downloader/core/errors/error_translators/error_translator.dart';

/// yt-dlp / ffmpeg failures, whether thrown in Dart ([EngineException]) or
/// coming back from the native engine ([PlatformException]).
final class EngineErrorTranslator implements ErrorTranslator<Object> {
  @override
  bool matches(Object error) => error is EngineException || error is PlatformException;

  @override
  FailureState<T> translate<T>(Object error) {
    final output = switch (error) {
      EngineException(:final output) => output,
      PlatformException(:final message, :final details) => '$message $details',
      _ => '$error',
    };
    return FailureState(message: EngineErrors.messageFor(output), error: output);
  }
}

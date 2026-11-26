import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/error_translators/error_translator.dart';
import 'package:media_downloader/core/errors/extractor_errors.dart';

/// A photo extractor couldn't read a post (login wall, removed, page changed).
final class ExtractorErrorTranslator implements ErrorTranslator<ExtractorException> {
  @override
  bool matches(Object error) => error is ExtractorException;

  @override
  FailureState<T> translate<T>(ExtractorException error) =>
      FailureState(message: error.message, error: error.toString());
}

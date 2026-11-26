import 'package:dio/dio.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_translators/error_translator.dart';
import 'package:media_tool/core/messages/app_messages.dart';

/// HTTP failures of the photo extractors and direct downloads. The logged
/// error has the host and path only: no query string, headers or cookies.
final class DioErrorTranslator implements ErrorTranslator<DioException> {
  @override
  bool matches(Object error) => error is DioException;

  @override
  FailureState<T> translate<T>(DioException error) {
    final code = error.response?.statusCode;
    final message = switch (error.type) {
      .badResponse => switch (code) {
        401 || 403 => EngineMessages.forbidden,
        404 || 410 => ExtractorMessages.notFound,
        429 => ExtractorMessages.rateLimited,
        _ => ExtractorMessages.downloadFailed,
      },
      .connectionTimeout || .sendTimeout || .receiveTimeout || .connectionError => EngineMessages.network,
      _ => ExtractorMessages.downloadFailed,
    };
    final uri = error.requestOptions.uri;
    return FailureState(
      message: message,
      error: 'DioException ${error.type.name} ${code ?? ''} ${uri.host}${uri.path}',
    );
  }
}

import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_translators/error_translator.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:pdfrx/pdfrx.dart';

/// PDFium failures: a missing or wrong password, or a PDF it can't read or write.
final class PdfErrorTranslator implements ErrorTranslator<PdfException> {
  @override
  bool matches(Object error) => error is PdfException;

  @override
  FailureState<T> translate<T>(PdfException error) => FailureState(
    message: error is PdfPasswordException ? ToolsMessages.wrongPassword : ToolsMessages.pdfFailed,
    error: error.toString(),
  );
}

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/injector.config.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/errors/error_recorders/app_error_recorder.dart';
import 'package:media_tool/core/errors/error_recorders/logger_error_recorder.dart';
import 'package:media_tool/core/errors/error_translators/dio_error_translator.dart';
import 'package:media_tool/core/errors/error_translators/engine_error_translator.dart';
import 'package:media_tool/core/errors/error_translators/extractor_error_translator.dart';
import 'package:media_tool/core/errors/error_translators/file_system_error_translator.dart';
import 'package:media_tool/core/errors/error_translators/gallery_error_translator.dart';
import 'package:media_tool/core/errors/error_translators/pdf_error_translator.dart';

@InjectableInit(initializerName: 'initialize')
Future<void> configureDependencies({required String environment}) async {
  // Order matters: the error log needs the database, the handler needs both.
  final database = AppDatabaseProvider.register();
  AppErrorProvider.register(database);
  ErrorHandlerProvider.register(
    errorTranslators: [
      FileSystemErrorTranslator(),
      GalleryErrorTranslator(),
      PdfErrorTranslator(),
      ExtractorErrorTranslator(),
      DioErrorTranslator(),
      EngineErrorTranslator(),
    ],
    errorRecorders: [AppErrorProvider.I, LoggerErrorRecorder()],
  );

  GetIt.I.initialize(environment: environment);
}

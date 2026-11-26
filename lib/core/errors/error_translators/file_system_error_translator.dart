import 'dart:io';

import 'package:media_downloader/core/data/states/data_state.dart';
import 'package:media_downloader/core/errors/error_translators/error_translator.dart';
import 'package:media_downloader/core/messages/app_messages.dart';

/// Turns file system errors into a storage failure.
final class FileSystemErrorTranslator implements ErrorTranslator<FileSystemException> {
  // errno 28 is ENOSPC on Android, iOS and macOS.
  static const _noSpaceErrorCode = 28;

  @override
  bool matches(Object error) => error is FileSystemException;

  @override
  FailureState<T> translate<T>(FileSystemException error) => FailureState(
    message: error.osError?.errorCode == _noSpaceErrorCode ? CommonMessages.noSpace : CommonMessages.storageError,
    error: error.toString(),
  );
}

import 'dart:io';

import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_translators/error_translator.dart';
import 'package:media_tool/core/messages/app_messages.dart';

/// Turns file system errors into a storage failure.
final class FileSystemErrorTranslator implements ErrorTranslator<FileSystemException> {
  // errno 28 is ENOSPC on Android, iOS, macOS and Linux; Windows reports
  // ERROR_HANDLE_DISK_FULL (39) or ERROR_DISK_FULL (112).
  static final _noSpaceErrorCodes = Platform.isWindows ? const {39, 112} : const {28};

  @override
  bool matches(Object error) => error is FileSystemException;

  @override
  FailureState<T> translate<T>(FileSystemException error) => FailureState(
    message: _noSpaceErrorCodes.contains(error.osError?.errorCode) ? CommonMessages.noSpace : CommonMessages.storageError,
    error: error.toString(),
  );
}

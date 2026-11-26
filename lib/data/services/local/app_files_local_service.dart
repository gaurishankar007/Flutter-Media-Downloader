import 'dart:io';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/services/app_directories.dart';

/// How much space the app's own folder ([AppDirectories.base]) takes. Throws;
/// the repository calls it inside `ErrorHandler`.
abstract interface class AppFilesLocalService {
  Future<int> sizeInBytes();
}

@LazySingleton(as: AppFilesLocalService)
final class AppFilesLocalServiceImpl({required final AppDirectories _directories}) implements AppFilesLocalService {
  // The Library can hold thousands of files; walk them off the UI isolate.
  @override
  Future<int> sizeInBytes() {
    final base = _directories.base;
    return Isolate.run(() => _sizeOf(base));
  }

  static Future<int> _sizeOf(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return 0;
    }
    var total = 0;
    // An unreadable folder or a file deleted mid-walk is skipped, not fatal.
    final entities = directory.list(recursive: true, followLinks: false).handleError((Object _) {});
    await for (final entity in entities) {
      if (entity is File) {
        final stat = entity.statSync();
        if (stat.type == .file) {
          total += stat.size;
        }
      }
    }
    return total;
  }
}

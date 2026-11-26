import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/data/services/platform/file_export/file_export_service.dart';

/// `NSSavePanel` (through file_picker), then a streamed copy to the chosen path.
@LazySingleton(as: FileExportService, env: [PlatformEnv.macos])
final class MacosFileExportService implements FileExportService {
  @override
  Future<bool> export(String path, {required String name, required String mimeType}) async {
    // On macOS file_picker only writes the (empty) bytes after the panel, so
    // the real file is copied over it without loading it into memory.
    final target = await FilePicker.saveFile(fileName: name, bytes: Uint8List(0), mimeType: mimeType);
    if (target == null) {
      return false;
    }
    await File(path).copy(target.toFilePath());
    return true;
  }
}

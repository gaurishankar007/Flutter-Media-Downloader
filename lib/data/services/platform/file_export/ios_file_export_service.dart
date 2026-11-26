import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/clients/platform/file_export_api.g.dart';
import 'package:media_tool/data/services/platform/file_export/file_export_service.dart';

/// `UIDocumentPickerViewController(forExporting:)` through Pigeon (Swift:
/// `Export/FileExporter.swift`).
@LazySingleton(as: FileExportService, env: [PlatformEnv.ios])
final class IosFileExportService implements FileExportService {
  final _api = FileExportHostApi();

  @override
  Future<bool> export(String path, {required String name, required String mimeType}) async {
    try {
      return await _api.exportFile(path, name, mimeType);
    } on PlatformException catch (error) {
      // A storage failure, not an engine one (EngineErrorTranslator takes every PlatformException).
      throw FileSystemException(error.message ?? error.code, path);
    }
  }
}

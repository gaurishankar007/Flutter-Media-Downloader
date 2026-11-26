import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// The system file picker, for single files the app reads once (cookies.txt).
abstract interface class FilePickerService {
  /// The picked file's path (a temporary copy on mobile), or `null` when cancelled.
  Future<String?> pickFile();

  /// Deletes the temporary copies [pickFile] made.
  Future<void> clearTemporaryFiles();
}

@LazySingleton(as: FilePickerService)
final class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<String?> pickFile() async => (await FilePicker.pickFile())?.path;

  @override
  Future<void> clearTemporaryFiles() => FilePicker.clearTemporaryFiles();
}

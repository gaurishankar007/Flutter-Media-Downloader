import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// Picks one video, audio or image file for the converter. On mobile the
/// picker hands back a temporary copy; [clearTemporaryFiles] deletes those.
abstract interface class MediaPickerService {
  /// A video or photo from Photos / the gallery, or null when cancelled.
  Future<String?> pickFromPhotos();

  /// Any file from the system file picker, or null when cancelled.
  Future<String?> pickFromFiles();

  Future<void> clearTemporaryFiles();
}

@LazySingleton(as: MediaPickerService)
final class MediaPickerServiceImpl implements MediaPickerService {
  @override
  Future<String?> pickFromPhotos() async => (await FilePicker.pickFile(type: .media))?.path;

  @override
  Future<String?> pickFromFiles() async => (await FilePicker.pickFile())?.path;

  @override
  Future<void> clearTemporaryFiles() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // Desktop pickers make no copies.
    }
  }
}

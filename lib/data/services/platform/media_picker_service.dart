import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// What the tools' pickers may show.
enum PickerFilter { images, videos, extensions }

/// Picks video, audio, image or PDF files for the converter and the tools. On
/// mobile the picker hands back temporary copies; [clearTemporaryFiles]
/// deletes those.
abstract interface class MediaPickerService {
  /// A video or photo from Photos / the gallery, or null when cancelled.
  Future<String?> pickFromPhotos();

  /// Any file from the system file picker, or null when cancelled.
  Future<String?> pickFromFiles();

  /// One or ([multiple]) several files: images or videos from Photos /
  /// the gallery when [fromPhotos], else from the file picker limited to
  /// [extensions]. Empty when cancelled.
  Future<List<String>> pickMany({
    required PickerFilter filter,
    required bool fromPhotos,
    required bool multiple,
    Set<String> extensions = const {},
  });

  Future<void> clearTemporaryFiles();
}

@LazySingleton(as: MediaPickerService)
final class MediaPickerServiceImpl implements MediaPickerService {
  @override
  Future<String?> pickFromPhotos() async => (await FilePicker.pickFile(type: .media))?.path;

  @override
  Future<String?> pickFromFiles() async => (await FilePicker.pickFile())?.path;

  @override
  Future<List<String>> pickMany({
    required PickerFilter filter,
    required bool fromPhotos,
    required bool multiple,
    Set<String> extensions = const {},
  }) async {
    final type = switch (filter) {
      _ when !fromPhotos && extensions.isNotEmpty => FileType.custom,
      .images => FileType.image,
      .videos => FileType.video,
      .extensions => FileType.any,
    };
    final allowed = type == .custom ? extensions.toList() : null;
    if (!multiple) {
      final file = await FilePicker.pickFile(type: type, allowedExtensions: allowed);
      return [?file?.path];
    }
    final files = await FilePicker.pickFiles(type: type, allowedExtensions: allowed);
    return [for (final file in files) ?file.path];
  }

  @override
  Future<void> clearTemporaryFiles() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // Desktop pickers make no copies.
    }
  }
}

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Image and player sources for files in the app's folder. Only builds handles
/// (no file I/O), so Views stay off `dart:io`.
abstract final class LocalMedia {
  static ImageProvider image(String path) => FileImage(File(path));

  static VideoPlayerController player(String path) => VideoPlayerController.file(File(path));
}

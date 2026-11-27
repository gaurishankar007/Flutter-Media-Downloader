import 'dart:io';

import 'package:gal/gal.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:path/path.dart' as p;

/// Save to Photos (iOS / macOS), the gallery (Android), the Pictures library
/// (Windows) or the Pictures / Videos folders (Linux). Methods throw
/// (`GalException`); repositories call them inside `ErrorHandler.execute`.
abstract interface class GalleryService {
  /// Whether [kind] can go to Photos / the gallery at all (audio can't).
  bool supports(MediaKind kind);

  Future<void> save(String path, MediaKind kind);
}

@LazySingleton(as: GalleryService, env: [PlatformEnv.android, PlatformEnv.ios, PlatformEnv.macos, PlatformEnv.windows])
final class GalleryServiceImpl implements GalleryService {
  static const _album = 'MediaTool';

  @override
  bool supports(MediaKind kind) => kind != .audio;

  @override
  Future<void> save(String path, MediaKind kind) async {
    // Asks once; a denial surfaces as GalException(permissionDenied) from put*.
    if (!await Gal.hasPermission(toAlbum: true)) {
      await Gal.requestPermission(toAlbum: true);
    }
    switch (kind) {
      case .video:
        await Gal.putVideo(path, album: _album);
      case .photo:
        await Gal.putImage(path, album: _album);
      case .audio:
        throw UnsupportedError('Audio files cannot be saved to Photos');
    }
  }
}

/// Linux has no photo library: copies into `MediaTool/` inside the user's
/// Pictures or Videos folder (`xdg-user-dir`, else ~/Pictures, ~/Videos).
@LazySingleton(as: GalleryService, env: [PlatformEnv.linux])
final class LinuxGalleryService implements GalleryService {
  @override
  bool supports(MediaKind kind) => kind != .audio;

  @override
  Future<void> save(String path, MediaKind kind) async {
    final folder = switch (kind) {
      .video => await _userDir('VIDEOS', 'Videos'),
      .photo => await _userDir('PICTURES', 'Pictures'),
      .audio => throw UnsupportedError('Audio files cannot be saved to Photos'),
    };
    final album = Directory(p.join(folder, 'MediaTool'));
    await album.create(recursive: true);
    await File(path).copy(await _freeName(album.path, p.basename(path)));
  }

  Future<String> _userDir(String key, String fallback) async {
    final home = Platform.environment['HOME'] ?? '.';
    try {
      final result = await Process.run('xdg-user-dir', [key]);
      final dir = (result.stdout as String).trim();
      // xdg-user-dir answers $HOME when the folder isn't configured.
      if (result.exitCode == 0 && dir.isNotEmpty && dir != home) {
        return dir;
      }
    } on ProcessException {
      // Not installed: use the usual folder.
    }
    return p.join(home, fallback);
  }

  /// `name.mp4`, else `name (2).mp4`, … so an earlier save is never overwritten.
  Future<String> _freeName(String folder, String name) async {
    final stem = p.basenameWithoutExtension(name);
    final extension = p.extension(name);
    var candidate = p.join(folder, name);
    for (var i = 2; File(candidate).existsSync(); i++) {
      candidate = p.join(folder, '$stem ($i)$extension');
    }
    return candidate;
  }
}

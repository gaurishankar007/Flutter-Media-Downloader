import 'package:gal/gal.dart';
import 'package:injectable/injectable.dart';
import 'package:media_downloader/domain/models/media_kind.dart';

/// Save to Photos (iOS / macOS) or the gallery (Android). Methods throw
/// (`GalException`); repositories call them inside `ErrorHandler.execute`.
abstract interface class GalleryService {
  /// Whether [kind] can go to Photos / the gallery at all (audio can't).
  bool supports(MediaKind kind);

  Future<void> save(String path, MediaKind kind);
}

@LazySingleton(as: GalleryService)
final class GalleryServiceImpl implements GalleryService {
  static const _album = 'MediaDownloader';

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

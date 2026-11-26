import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/ui/core/utils/local_media.dart';
import 'package:media_downloader/ui/features/library/models/library_entry.dart';

/// A zoomable photo.
class const PhotoViewer({super.key, required final LibraryEntry entry}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 5,
      child: Center(
        child: Hero(
          tag: 'library-${entry.id}',
          child: Image(image: LocalMedia.image(entry.filePath), fit: .contain),
        ),
      ),
    );
  }
}

import 'package:media_downloader/domain/models/media_kind.dart';

/// One downloaded file of a photo post, still in the job's work folder.
typedef PostFile = ({String path, MediaKind kind, String? thumbnailPath});

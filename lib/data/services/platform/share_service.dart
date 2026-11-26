import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

/// The system share sheet.
abstract interface class ShareService {
  Future<void> shareFiles(List<String> paths);
}

@LazySingleton(as: ShareService)
final class ShareServiceImpl implements ShareService {
  @override
  Future<void> shareFiles(List<String> paths) async {
    await SharePlus.instance.share(ShareParams(files: [for (final path in paths) XFile(path)]));
  }
}

import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The app's folders, resolved once at startup by [init]. Paths stored in the
/// database are relative to [base]. See docs/core/core_services.md#app-directories.
@singleton
final class AppDirectories {
  late final String base;
  late final String downloads;
  late final String thumbnails;

  /// Imported cookies.txt per site. Never backed up, logged or uploaded.
  late final String cookies;
  late final String work;
  bool _initialized = false;

  /// Safe to call again (startup Retry); only the first call does anything.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    base = (await getApplicationSupportDirectory()).path;
    downloads = p.join(base, 'downloads');
    thumbnails = p.join(base, 'thumbnails');
    cookies = p.join(base, 'cookies');
    work = p.join((await getApplicationCacheDirectory()).path, 'work');

    // Anything left in work/ is a partial file from a run that was killed.
    final workDir = Directory(work);
    if (workDir.existsSync()) {
      await workDir.delete(recursive: true);
    }
    for (final dir in [downloads, thumbnails, cookies, work]) {
      await Directory(dir).create(recursive: true);
    }
  }

  /// The scratch folder of one job.
  String workFor(String jobId) => p.join(work, jobId);

  /// The absolute path of a path stored relative to [base].
  String resolve(String relativePath) => p.join(base, relativePath);

  /// [absolutePath] relative to [base], for storing in the database.
  String relative(String absolutePath) => p.relative(absolutePath, from: base);
}

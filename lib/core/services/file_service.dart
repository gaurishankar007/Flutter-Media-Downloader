import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

/// File operations, so nothing above the data layer uses `dart:io`. Methods
/// throw; repositories call them inside `ErrorHandler.execute`.
abstract interface class FileService {
  /// Moves [from] to [to], copying across file systems when a rename can't.
  Future<void> move(String from, String to);

  /// Copies [from] to [to], creating [to]'s folder.
  Future<void> copy(String from, String to);

  /// Creates [dir] and its parents if missing.
  Future<void> createDir(String dir);

  /// Deletes a file or folder if it exists.
  Future<void> delete(String path);

  Future<int> sizeOf(String path);

  /// Files directly inside [dir] (none when it doesn't exist).
  Future<List<String>> listFiles(String dir);

  /// [name] in [dir], with " (2)", " (3)"… added before the extension on a clash.
  String uniqueName(String dir, String name);
}

@LazySingleton(as: FileService)
final class FileServiceImpl implements FileService {
  @override
  Future<void> move(String from, String to) async {
    await Directory(p.dirname(to)).create(recursive: true);
    try {
      await File(from).rename(to);
    } on FileSystemException {
      // Cache and files dirs can sit on different mounts.
      await File(from).copy(to);
      await File(from).delete();
    }
  }

  @override
  Future<void> copy(String from, String to) async {
    await Directory(p.dirname(to)).create(recursive: true);
    await File(from).copy(to);
  }

  @override
  Future<void> createDir(String dir) async {
    await Directory(dir).create(recursive: true);
  }

  @override
  Future<void> delete(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == .notFound) {
      return;
    }
    await (type == .directory ? Directory(path) : File(path)).delete(recursive: true);
  }

  @override
  Future<int> sizeOf(String path) => File(path).length();

  @override
  Future<List<String>> listFiles(String dir) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      return const [];
    }
    return [
      await for (final entity in directory.list())
        if (entity is File) entity.path,
    ];
  }

  @override
  String uniqueName(String dir, String name) {
    final stem = p.basenameWithoutExtension(name);
    final extension = p.extension(name);
    var candidate = name;
    for (var index = 2; File(p.join(dir, candidate)).existsSync(); index++) {
      candidate = '$stem ($index)$extension';
    }
    return candidate;
  }
}

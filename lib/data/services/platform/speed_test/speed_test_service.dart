import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:injectable/injectable.dart';

/// Measured throughput in bytes per second.
typedef RawSpeed = ({double read, double write, double? copy});

/// RAM and storage speed tests. They call libc through `dart:ffi` (memset,
/// memchr, memcpy, open/read/write) so they run at native speed even in debug
/// builds, and they bypass the system cache: `F_NOCACHE` on iOS/macOS,
/// `posix_fadvise(DONTNEED)` after `fsync` on Android. Each runs in its own
/// isolate. Methods throw; the repository calls them inside `ErrorHandler`.
abstract interface class SpeedTestService {
  /// Fills, scans and copies a [bytes]-sized block of RAM.
  Future<RawSpeed> memory(int bytes);

  /// Writes a [bytes]-sized file to [path], reads it back and deletes it.
  Future<RawSpeed> storage(String path, int bytes);
}

@LazySingleton(as: SpeedTestService)
final class SpeedTestServiceImpl implements SpeedTestService {
  @override
  Future<RawSpeed> memory(int bytes) => Isolate.run(() => _memoryTest(bytes));

  @override
  Future<RawSpeed> storage(String path, int bytes) => Isolate.run(() => _storageTest(path, bytes));
}

/// Each RAM pass repeats until this much time has passed, so short passes still time well.
const _minPassMicros = 250000;
const _storageChunk = 4 * 1024 * 1024;
const _pageAlignment = 16384;

RawSpeed _memoryTest(int bytes) {
  final libc = _Libc();
  final source = libc.alignedAlloc(bytes);
  final target = libc.alignedAlloc(bytes);
  try {
    // Touches every page first, so page faults don't count as RAM speed.
    libc
      ..memset(source, 0, bytes)
      ..memset(target, 0, bytes);
    double throughput(void Function(int pass) run) {
      final watch = Stopwatch()..start();
      var passes = 0;
      while (watch.elapsedMicroseconds < _minPassMicros) {
        run(passes++);
      }
      return bytes * passes / (watch.elapsedMicroseconds / Duration.microsecondsPerSecond);
    }

    final write = throughput((pass) => libc.memset(source, pass & 0x7f, bytes));
    // Searching for a byte that isn't there reads the whole block.
    final read = throughput((_) => libc.memchr(source, 0xff, bytes));
    final copy = throughput((_) => libc.memcpy(target, source, bytes));
    return (read: read, write: write, copy: copy);
  } finally {
    libc
      ..free(source)
      ..free(target);
  }
}

RawSpeed _storageTest(String path, int bytes) {
  final libc = _Libc();
  final chunk = libc.alignedAlloc(_storageChunk);
  final file = File(path);
  try {
    // Random data, so a drive that compresses can't cheat.
    final random = Random();
    final words = chunk.cast<Uint32>().asTypedList(_storageChunk ~/ 4);
    for (var i = 0; i < words.length; i++) {
      words[i] = random.nextInt(1 << 32);
    }
    final chunks = bytes ~/ _storageChunk;

    var watch = Stopwatch()..start();
    var fd = libc.open(path, libc.writeFlags);
    try {
      for (var i = 0; i < chunks; i++) {
        libc.writeAll(fd, chunk, _storageChunk);
      }
      libc
        ..flush(fd)
        ..dropCache(fd);
    } finally {
      libc.close(fd);
    }
    final writeSeconds = watch.elapsedMicroseconds / Duration.microsecondsPerSecond;

    fd = libc.open(path, libc.readFlags);
    try {
      libc.dropCache(fd);
      watch = Stopwatch()..start();
      var total = 0;
      while (total < chunks * _storageChunk) {
        final read = libc.read(fd, chunk, _storageChunk);
        if (read <= 0) {
          break;
        }
        total += read;
      }
      final readSeconds = watch.elapsedMicroseconds / Duration.microsecondsPerSecond;
      return (read: total / readSeconds, write: chunks * _storageChunk / writeSeconds, copy: null);
    } finally {
      libc.close(fd);
    }
  } finally {
    libc.free(chunk);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

/// The few libc calls the tests need. Flag values differ between Linux
/// (Android) and Darwin (iOS, macOS).
final class _Libc {
  final DynamicLibrary _lib = Platform.isAndroid ? DynamicLibrary.open('libc.so') : DynamicLibrary.process();

  static final _darwin = Platform.isIOS || Platform.isMacOS;
  static const _oRdonly = 0;
  static const _oWronly = 1;
  static final _oCreat = _darwin ? 0x200 : 0x40;
  static final _oTrunc = _darwin ? 0x400 : 0x200;
  static const _fNoCache = 48;
  static const _fFullFsync = 51;
  static const _posixFadvDontNeed = 4;

  int get writeFlags => _oWronly | _oCreat | _oTrunc;

  int get readFlags => _oRdonly;

  late final _open = _lib
      .lookupFunction<Int Function(Pointer<Uint8>, Int, VarArgs<(Int,)>), int Function(Pointer<Uint8>, int, int)>(
        'open',
      );
  late final close = _lib.lookupFunction<Int Function(Int), int Function(int)>('close');
  late final _write = _lib
      .lookupFunction<IntPtr Function(Int, Pointer<Void>, Size), int Function(int, Pointer<Void>, int)>('write');
  late final read = _lib
      .lookupFunction<IntPtr Function(Int, Pointer<Void>, Size), int Function(int, Pointer<Void>, int)>('read');
  late final _fsync = _lib.lookupFunction<Int Function(Int), int Function(int)>('fsync');
  late final _fcntl = _lib.lookupFunction<Int Function(Int, Int, VarArgs<(Int,)>), int Function(int, int, int)>(
    'fcntl',
  );
  late final _fadvise = _lib.lookupFunction<Int Function(Int, Long, Long, Int), int Function(int, int, int, int)>(
    'posix_fadvise',
  );
  late final _memalign = _lib
      .lookupFunction<Int Function(Pointer<Pointer<Void>>, Size, Size), int Function(Pointer<Pointer<Void>>, int, int)>(
        'posix_memalign',
      );
  late final _malloc = _lib.lookupFunction<Pointer<Void> Function(Size), Pointer<Void> Function(int)>('malloc');
  late final free = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('free');
  late final memset = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memset', isLeaf: true);
  late final memchr = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memchr', isLeaf: true);
  late final memcpy = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Size),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int)
      >('memcpy', isLeaf: true);

  Pointer<Void> alignedAlloc(int bytes) {
    final out = _malloc(sizeOf<Pointer<Void>>()).cast<Pointer<Void>>();
    try {
      if (_memalign(out, _pageAlignment, bytes) != 0) {
        throw const OSError('Out of memory for the speed test');
      }
      return out.value;
    } finally {
      free(out.cast());
    }
  }

  /// Opens [path] with caching disabled on iOS/macOS.
  int open(String path, int flags) {
    final encoded = utf8.encode(path);
    final cPath = _malloc(encoded.length + 1).cast<Uint8>();
    try {
      cPath.asTypedList(encoded.length + 1)
        ..setAll(0, encoded)
        ..[encoded.length] = 0;
      final fd = _open(cPath, flags, 420); // 0644
      if (fd < 0) {
        throw FileSystemException('Could not open the speed test file', path);
      }
      if (_darwin) {
        _fcntl(fd, _fNoCache, 1);
      }
      return fd;
    } finally {
      free(cPath.cast());
    }
  }

  void writeAll(int fd, Pointer<Void> buffer, int length) {
    var written = 0;
    while (written < length) {
      final result = _write(fd, Pointer.fromAddress(buffer.address + written), length - written);
      if (result <= 0) {
        throw const FileSystemException('Could not write the speed test file');
      }
      written += result;
    }
  }

  /// Pushes the data to the drive itself (Darwin's fsync stops at the drive's cache).
  void flush(int fd) {
    if (_darwin && _fcntl(fd, _fFullFsync, 0) == 0) {
      return;
    }
    _fsync(fd);
  }

  /// Android: evicts the file's (clean) pages, so the read comes from flash.
  void dropCache(int fd) {
    if (Platform.isAndroid) {
      _fadvise(fd, 0, 0, _posixFadvDontNeed);
    }
  }
}

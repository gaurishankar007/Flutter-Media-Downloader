import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:injectable/injectable.dart';

/// Measured throughput in bytes per second.
typedef RawSpeed = ({double read, double write, double? copy});

/// RAM and storage speed tests. They call libc (Windows: ntdll / kernel32)
/// through `dart:ffi` (memset, memchr, memcpy, open/read/write) so they run at
/// native speed even in debug builds, and they bypass the system cache:
/// `F_NOCACHE` on iOS/macOS, `posix_fadvise(DONTNEED)` after `fsync` on
/// Android and Linux, unbuffered write-through handles on Windows. Each runs
/// in its own isolate. Methods throw; the repository calls them inside `ErrorHandler`.
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
  final libc = _NativeIo();
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
      ..release(source)
      ..release(target);
  }
}

RawSpeed _storageTest(String path, int bytes) {
  final libc = _NativeIo();
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
    libc.release(chunk);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

/// The native calls the tests need: libc on Android, iOS, macOS and Linux,
/// Win32 on Windows. Files are plain ints (fd or HANDLE address).
abstract interface class _NativeIo {
  factory() => Platform.isWindows ? _Win32Io() : _Libc();

  int get writeFlags;

  int get readFlags;

  Pointer<Void> alignedAlloc(int bytes);

  void release(Pointer<Void> pointer);

  Pointer<Void> memset(Pointer<Void> pointer, int value, int bytes);

  Pointer<Void> memchr(Pointer<Void> pointer, int value, int bytes);

  Pointer<Void> memcpy(Pointer<Void> target, Pointer<Void> source, int bytes);

  int open(String path, int flags);

  void writeAll(int fd, Pointer<Void> buffer, int length);

  int read(int fd, Pointer<Void> buffer, int length);

  void flush(int fd);

  void dropCache(int fd);

  void close(int fd);
}

/// libc. Flag values differ between Linux (Android, Linux) and Darwin (iOS, macOS).
final class _Libc implements _NativeIo {
  final DynamicLibrary _lib = switch (Platform.operatingSystem) {
    'android' => DynamicLibrary.open('libc.so'),
    'linux' => DynamicLibrary.open('libc.so.6'),
    _ => DynamicLibrary.process(),
  };

  static final _darwin = Platform.isIOS || Platform.isMacOS;
  static const _oRdonly = 0;
  static const _oWronly = 1;
  static final _oCreat = _darwin ? 0x200 : 0x40;
  static final _oTrunc = _darwin ? 0x400 : 0x200;
  static const _fNoCache = 48;
  static const _fFullFsync = 51;
  static const _posixFadvDontNeed = 4;

  @override
  int get writeFlags => _oWronly | _oCreat | _oTrunc;

  @override
  int get readFlags => _oRdonly;

  late final _open = _lib
      .lookupFunction<Int Function(Pointer<Uint8>, Int, VarArgs<(Int,)>), int Function(Pointer<Uint8>, int, int)>(
        'open',
      );
  late final _close = _lib.lookupFunction<Int Function(Int), int Function(int)>('close');
  late final _write = _lib
      .lookupFunction<IntPtr Function(Int, Pointer<Void>, Size), int Function(int, Pointer<Void>, int)>('write');
  late final _read = _lib
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
  late final _free = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('free');
  late final _memset = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memset', isLeaf: true);
  late final _memchr = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memchr', isLeaf: true);
  late final _memcpy = _lib
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Size),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int)
      >('memcpy', isLeaf: true);

  @override
  void release(Pointer<Void> pointer) => _free(pointer);

  @override
  Pointer<Void> memset(Pointer<Void> pointer, int value, int bytes) => _memset(pointer, value, bytes);

  @override
  Pointer<Void> memchr(Pointer<Void> pointer, int value, int bytes) => _memchr(pointer, value, bytes);

  @override
  Pointer<Void> memcpy(Pointer<Void> target, Pointer<Void> source, int bytes) => _memcpy(target, source, bytes);

  @override
  int read(int fd, Pointer<Void> buffer, int length) => _read(fd, buffer, length);

  @override
  void close(int fd) => _close(fd);

  @override
  Pointer<Void> alignedAlloc(int bytes) {
    final out = _malloc(sizeOf<Pointer<Void>>()).cast<Pointer<Void>>();
    try {
      if (_memalign(out, _pageAlignment, bytes) != 0) {
        throw const OSError('Out of memory for the speed test');
      }
      return out.value;
    } finally {
      _free(out.cast());
    }
  }

  /// Opens [path] with caching disabled on iOS/macOS.
  @override
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
      _free(cPath.cast());
    }
  }

  @override
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
  @override
  void flush(int fd) {
    if (_darwin && _fcntl(fd, _fFullFsync, 0) == 0) {
      return;
    }
    _fsync(fd);
  }

  /// Android / Linux: evicts the file's (clean) pages, so the read comes from the drive.
  @override
  void dropCache(int fd) {
    if (!_darwin) {
      _fadvise(fd, 0, 0, _posixFadvDontNeed);
    }
  }
}

/// Win32: page-aligned VirtualAlloc memory, ntdll's mem* routines and
/// unbuffered write-through file handles (no system cache to bypass).
final class _Win32Io implements _NativeIo {
  static const _genericRead = 0x80000000;
  static const _genericWrite = 0x40000000;
  static const _createAlways = 2;
  static const _openExisting = 3;
  static const _noBuffering = 0x20000000;
  static const _writeThrough = 0x80000000;
  static const _memCommitReserve = 0x3000;
  static const _memRelease = 0x8000;
  static const _pageReadWrite = 0x04;

  final _kernel32 = DynamicLibrary.open('kernel32.dll');
  final _ntdll = DynamicLibrary.open('ntdll.dll');

  late final _virtualAlloc = _kernel32
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Size, Uint32, Uint32),
        Pointer<Void> Function(Pointer<Void>, int, int, int)
      >('VirtualAlloc');
  late final _virtualFree = _kernel32
      .lookupFunction<Int32 Function(Pointer<Void>, Size, Uint32), int Function(Pointer<Void>, int, int)>(
        'VirtualFree',
      );
  late final _createFile = _kernel32
      .lookupFunction<
        IntPtr Function(Pointer<Uint16>, Uint32, Uint32, Pointer<Void>, Uint32, Uint32, IntPtr),
        int Function(Pointer<Uint16>, int, int, Pointer<Void>, int, int, int)
      >('CreateFileW');
  late final _writeFile = _kernel32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>, Pointer<Void>),
        int Function(int, Pointer<Void>, int, Pointer<Uint32>, Pointer<Void>)
      >('WriteFile');
  late final _readFile = _kernel32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>, Pointer<Void>),
        int Function(int, Pointer<Void>, int, Pointer<Uint32>, Pointer<Void>)
      >('ReadFile');
  late final _flushFileBuffers = _kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
    'FlushFileBuffers',
  );
  late final _closeHandle = _kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
  late final _memset = _ntdll
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memset', isLeaf: true);
  late final _memchr = _ntdll
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Int, Size),
        Pointer<Void> Function(Pointer<Void>, int, int)
      >('memchr', isLeaf: true);
  late final _memcpy = _ntdll
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Size),
        Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int)
      >('memcpy', isLeaf: true);

  @override
  int get writeFlags => _genericWrite;

  @override
  int get readFlags => _genericRead;

  @override
  Pointer<Void> alignedAlloc(int bytes) {
    final pointer = _virtualAlloc(nullptr, bytes, _memCommitReserve, _pageReadWrite);
    if (pointer == nullptr) {
      throw const OSError('Out of memory for the speed test');
    }
    return pointer;
  }

  @override
  void release(Pointer<Void> pointer) => _virtualFree(pointer, 0, _memRelease);

  @override
  Pointer<Void> memset(Pointer<Void> pointer, int value, int bytes) => _memset(pointer, value, bytes);

  @override
  Pointer<Void> memchr(Pointer<Void> pointer, int value, int bytes) => _memchr(pointer, value, bytes);

  @override
  Pointer<Void> memcpy(Pointer<Void> target, Pointer<Void> source, int bytes) => _memcpy(target, source, bytes);

  @override
  int open(String path, int flags) {
    final units = [...path.codeUnits, 0];
    final widePath = alignedAlloc(units.length * 2).cast<Uint16>();
    try {
      widePath.asTypedList(units.length).setAll(0, units);
      final handle = _createFile(
        widePath,
        flags,
        0,
        nullptr,
        flags == _genericWrite ? _createAlways : _openExisting,
        _noBuffering | _writeThrough,
        0,
      );
      // INVALID_HANDLE_VALUE is -1.
      if (handle == -1 || handle == 0) {
        throw FileSystemException('Could not open the speed test file', path);
      }
      return handle;
    } finally {
      release(widePath.cast());
    }
  }

  @override
  void writeAll(int fd, Pointer<Void> buffer, int length) {
    final written = alignedAlloc(4).cast<Uint32>();
    try {
      var total = 0;
      while (total < length) {
        if (_writeFile(fd, Pointer.fromAddress(buffer.address + total), length - total, written, nullptr) == 0 ||
            written.value == 0) {
          throw const FileSystemException('Could not write the speed test file');
        }
        total += written.value;
      }
    } finally {
      release(written.cast());
    }
  }

  @override
  int read(int fd, Pointer<Void> buffer, int length) {
    final read = alignedAlloc(4).cast<Uint32>();
    try {
      return _readFile(fd, buffer, length, read, nullptr) == 0 ? -1 : read.value;
    } finally {
      release(read.cast());
    }
  }

  @override
  void flush(int fd) => _flushFileBuffers(fd);

  /// Unbuffered handles never touch the system cache.
  @override
  void dropCache(int fd) {}

  @override
  void close(int fd) => _closeHandle(fd);
}

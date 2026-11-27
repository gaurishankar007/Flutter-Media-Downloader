import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:path/path.dart' as p;

/// Where the bundled yt-dlp / ffmpeg live on a desktop and how to run them:
/// `Contents/Resources/bin/` on macOS, `bin/` next to the executable on
/// Windows and Linux. See docs/engine/desktop_engine.md.
@LazySingleton(env: PlatformEnv.desktop)
final class DesktopEngineBinaries({required final AppDirectories _directories}) {
  static const _killGrace = Duration(seconds: 3);

  String get bin => Platform.isMacOS
      ? p.normalize(p.join(p.dirname(Platform.resolvedExecutable), '..', 'Resources', 'bin'))
      : p.join(p.dirname(Platform.resolvedExecutable), 'bin');

  String get ffmpeg => p.join(bin, _exe('ffmpeg'));

  String get bundledYtDlp => p.join(bin, _ytDlpName);

  /// The writable copy that runs, so `yt-dlp -U` can update it.
  String get ytDlpCopy => p.join(_directories.base, 'engine', _ytDlpName);

  /// The bundled deno for YouTube's JavaScript challenges, when there is one.
  String? get deno => File(p.join(bin, _exe('deno'))).existsSync() ? p.join(bin, _exe('deno')) : null;

  String get _ytDlpName => switch (Platform.operatingSystem) {
    'windows' => 'yt-dlp.exe',
    'linux' => 'yt-dlp_linux',
    _ => 'yt-dlp_macos',
  };

  String _exe(String name) => Platform.isWindows ? '$name.exe' : name;

  /// Bundled tools first on PATH (macOS: then Homebrew, for a deno that isn't
  /// bundled, since GUI apps start with a bare PATH), and UTF-8 output so
  /// titles and file names survive.
  Map<String, String> get environment {
    final inherited = Platform.environment['PATH'];
    return {
      'PATH': switch (Platform.operatingSystem) {
        'windows' => [bin, ?inherited].join(';'),
        'macos' => [bin, '/opt/homebrew/bin', '/usr/local/bin', inherited ?? '/usr/bin:/bin'].join(':'),
        _ => [bin, inherited ?? '/usr/local/bin:/usr/bin:/bin'].join(':'),
      },
      if (!Platform.isWindows) ...{
        'LANG': Platform.isLinux ? 'C.UTF-8' : 'en_US.UTF-8',
        'LC_ALL': Platform.isLinux ? 'C.UTF-8' : 'en_US.UTF-8',
      },
      'PYTHONUTF8': '1',
      'PYTHONIOENCODING': 'utf-8',
    };
  }

  /// Runs ffmpeg to completion (image jobs, no progress). Throws when it fails.
  Future<void> runFfmpeg(List<String> args) async {
    final result = await Process.run(ffmpeg, args, environment: environment, stderrEncoding: utf8);
    if (result.exitCode != 0) {
      final error = result.stderr as String;
      throw ProcessException(
        ffmpeg,
        args,
        error.length > 2000 ? error.substring(error.length - 2000) : error,
        result.exitCode,
      );
    }
  }

  /// Marks a copied binary as runnable (Windows needs nothing).
  Future<void> makeExecutable(String path) async {
    if (!Platform.isWindows) {
      await Process.run('chmod', ['755', path]);
    }
  }

  /// Stops [process] and everything it started: yt-dlp is a bootloader with
  /// Python (and ffmpeg) below it. SIGTERM first, SIGKILL after a grace
  /// period; Windows has no graceful stop for console programs.
  Future<void> killTree(Process process) async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
      return;
    }
    final tree = [process.pid, ...await _descendants(process.pid)]..forEach(Process.killPid);
    try {
      await process.exitCode.timeout(_killGrace);
    } on TimeoutException {
      final rest = [process.pid, ...await _descendants(process.pid)];
      for (final pid in {...tree, ...rest}) {
        Process.killPid(pid, .sigkill);
      }
    }
  }

  Future<List<int>> _descendants(int pid) async {
    final result = await Process.run('pgrep', ['-P', '$pid']);
    final children = const LineSplitter().convert(result.stdout as String).map(int.tryParse).nonNulls.toList();
    return [
      for (final child in children) ...[child, ...await _descendants(child)],
    ];
  }
}

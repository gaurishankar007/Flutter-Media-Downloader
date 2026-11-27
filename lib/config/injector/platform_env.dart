import 'dart:io';

/// Injectable environments, one per platform: only the running platform's
/// implementations get registered. See docs/architecture/architecture.md.
abstract final class PlatformEnv {
  static const android = 'android';
  static const ios = 'ios';
  static const macos = 'macos';
  static const windows = 'windows';
  static const linux = 'linux';

  /// The desktops, which run the bundled yt-dlp / ffmpeg binaries as processes.
  static const desktop = [macos, windows, linux];

  static String get current => switch (Platform.operatingSystem) {
    'android' => android,
    'ios' => ios,
    'windows' => windows,
    'linux' => linux,
    _ => macos,
  };
}

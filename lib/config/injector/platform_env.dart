import 'dart:io';

/// Injectable environments, one per platform: only the running platform's
/// implementations get registered. See docs/architecture/architecture.md.
abstract final class PlatformEnv {
  static const android = 'android';
  static const ios = 'ios';
  static const macos = 'macos';

  static String get current => switch (Platform.operatingSystem) {
    'android' => android,
    'ios' => ios,
    _ => macos,
  };
}

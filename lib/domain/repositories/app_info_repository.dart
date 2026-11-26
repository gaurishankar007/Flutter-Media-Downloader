import 'package:media_tool/core/types/types.dart';

/// Settings → About: app version and the local error log.
abstract interface class AppInfoRepository {
  FutureData<String> appVersion();

  /// Copies the error log to the clipboard; returns how many entries. It
  /// never leaves the device unless the user pastes it somewhere.
  FutureData<int> copyErrorLog();
}

import 'package:intl/intl.dart';
import 'package:media_tool/core/messages/app_messages.dart';

/// Human-readable sizes, durations and speeds.
abstract final class FormatUtils {
  static final _oneDecimal = NumberFormat('0.0');
  static final _noDecimal = NumberFormat('0');

  /// `840 KB`, `3.2 MB`, `1.2 GB`, `1.8 TB`.
  static String bytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    const tb = gb * 1024;
    if (bytes >= tb) {
      return '${_oneDecimal.format(bytes / tb)} TB';
    }
    if (bytes >= gb) {
      return '${_oneDecimal.format(bytes / gb)} GB';
    }
    if (bytes >= mb) {
      return '${(bytes >= 100 * mb ? _noDecimal : _oneDecimal).format(bytes / mb)} MB';
    }
    return '${_noDecimal.format((bytes / kb).clamp(1, kb))} KB';
  }

  /// `3.2 MB/s`.
  static String speed(double bytesPerSecond) => '${bytes(bytesPerSecond.round())}/s';

  /// `4:05`, `1:02:03`.
  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:${minutes.toString().padLeft(2, '0')}:$secs' : '$minutes:$secs';
  }

  /// `45 s left`, `3 min left`.
  static String eta(int seconds) =>
      seconds < 60 ? DownloadMessages.etaSeconds(seconds) : DownloadMessages.etaMinutes((seconds / 60).ceil());
}

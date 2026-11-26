import 'package:media_downloader/core/messages/app_messages.dart';

/// Thrown when yt-dlp or ffmpeg fails; [output] is its stderr.
final class const EngineException(final String output) implements Exception {
  @override
  String toString() => 'EngineException: $output';
}

/// Maps yt-dlp / ffmpeg error output to a user message. Order matters: more
/// specific patterns first. See docs/utils/troubleshooting.md.
abstract final class EngineErrors {
  static final _patterns = <(RegExp, String)>[
    (RegExp('not a bot', caseSensitive: false), EngineMessages.botCheck),
    (
      RegExp('private|log ?in|login required|sign in|members-only|age-restricted', caseSensitive: false),
      EngineMessages.needsLogin,
    ),
    (RegExp('Unsupported URL', caseSensitive: false), EngineMessages.unsupported),
    (
      RegExp('No video formats found|There is no video|No video could be found', caseSensitive: false),
      EngineMessages.noVideo,
    ),
    (
      RegExp('unavailable|has been removed|does not exist|not found|HTTP Error 404', caseSensitive: false),
      EngineMessages.unavailable,
    ),
    (RegExp('Requested format is not available', caseSensitive: false), EngineMessages.formatUnavailable),
    (RegExp('HTTP Error 403|Forbidden', caseSensitive: false), EngineMessages.forbidden),
    (
      RegExp(
        'Unable to download webpage|getaddrinfo|Network is unreachable|timed out|Connection reset|SSL',
        caseSensitive: false,
      ),
      EngineMessages.network,
    ),
    (RegExp('No space left', caseSensitive: false), CommonMessages.noSpace),
    (
      RegExp(
        'Unable to extract|Unable to parse|please report this issue|KeyError|JSONDecodeError',
        caseSensitive: false,
      ),
      EngineMessages.extractorBroken,
    ),
  ];

  static String messageFor(String output) {
    for (final (pattern, message) in _patterns) {
      if (pattern.hasMatch(output)) {
        return message;
      }
    }
    return EngineMessages.failed;
  }
}

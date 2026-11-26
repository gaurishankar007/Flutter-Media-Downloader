import 'package:equatable/equatable.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/app_theme_mode.dart';
import 'package:media_tool/domain/models/audio_quality.dart';
import 'package:media_tool/domain/models/cookie_browser.dart';
import 'package:media_tool/domain/models/video_quality.dart';

/// Every user setting. Stored as JSON under the `settings` key. See docs/features/settings.md.
final class const AppSettings({
  final AppThemeMode themeMode = .system,

  /// Whether the one-time rights notice was accepted.
  final bool rightsNoticeAccepted = false,

  /// Library: offer "remove from app?" after a confirmed Save to Photos / Files.
  final bool askRemoveAfterSave = true,

  /// Downloads: what the preview preselects.
  final VideoQuality defaultVideoQuality = .p1080,
  final AudioQuality defaultAudioQuality = .kbps320,
  final bool iphoneCompatible = true,

  /// Photos: convert WebP / HEIC to JPG (off keeps the original format).
  final bool photosToJpg = true,

  /// macOS: read cookies from this browser when a site has no cookies.txt.
  final CookieBrowser cookieBrowser = .none,

  /// Engine: look for a yt-dlp update at most once a day, after launch.
  final bool checkEngineOnLaunch = true,

  /// When the last launch check ran.
  final DateTime? lastEngineCheckAt,
}) extends Equatable {
  factory fromJson(JsonMap json) => AppSettings(
    themeMode: AppThemeMode.values.asNameMap()[json['themeMode']] ?? .system,
    rightsNoticeAccepted: json['rightsNoticeAccepted'] == true,
    askRemoveAfterSave: json['askRemoveAfterSave'] != false,
    defaultVideoQuality: VideoQuality.values.asNameMap()[json['defaultVideoQuality']] ?? .p1080,
    defaultAudioQuality: AudioQuality.values.asNameMap()[json['defaultAudioQuality']] ?? .kbps320,
    iphoneCompatible: json['iphoneCompatible'] != false,
    photosToJpg: json['photosToJpg'] != false,
    cookieBrowser: CookieBrowser.values.asNameMap()[json['cookieBrowser']] ?? .none,
    checkEngineOnLaunch: json['checkEngineOnLaunch'] != false,
    lastEngineCheckAt: DateTime.tryParse(json['lastEngineCheckAt'] as String? ?? ''),
  );

  JsonMap toJson() => {
    'themeMode': themeMode.name,
    'rightsNoticeAccepted': rightsNoticeAccepted,
    'askRemoveAfterSave': askRemoveAfterSave,
    'defaultVideoQuality': defaultVideoQuality.name,
    'defaultAudioQuality': defaultAudioQuality.name,
    'iphoneCompatible': iphoneCompatible,
    'photosToJpg': photosToJpg,
    'cookieBrowser': cookieBrowser.name,
    'checkEngineOnLaunch': checkEngineOnLaunch,
    'lastEngineCheckAt': lastEngineCheckAt?.toIso8601String(),
  };

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? rightsNoticeAccepted,
    bool? askRemoveAfterSave,
    VideoQuality? defaultVideoQuality,
    AudioQuality? defaultAudioQuality,
    bool? iphoneCompatible,
    bool? photosToJpg,
    CookieBrowser? cookieBrowser,
    bool? checkEngineOnLaunch,
    DateTime? lastEngineCheckAt,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    rightsNoticeAccepted: rightsNoticeAccepted ?? this.rightsNoticeAccepted,
    askRemoveAfterSave: askRemoveAfterSave ?? this.askRemoveAfterSave,
    defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
    defaultAudioQuality: defaultAudioQuality ?? this.defaultAudioQuality,
    iphoneCompatible: iphoneCompatible ?? this.iphoneCompatible,
    photosToJpg: photosToJpg ?? this.photosToJpg,
    cookieBrowser: cookieBrowser ?? this.cookieBrowser,
    checkEngineOnLaunch: checkEngineOnLaunch ?? this.checkEngineOnLaunch,
    lastEngineCheckAt: lastEngineCheckAt ?? this.lastEngineCheckAt,
  );

  @override
  List<Object?> get props => [
    themeMode,
    rightsNoticeAccepted,
    askRemoveAfterSave,
    defaultVideoQuality,
    defaultAudioQuality,
    iphoneCompatible,
    photosToJpg,
    cookieBrowser,
    checkEngineOnLaunch,
    lastEngineCheckAt,
  ];
}

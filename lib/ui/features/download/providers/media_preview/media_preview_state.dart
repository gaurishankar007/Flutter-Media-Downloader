part of 'media_preview_notifier.dart';

enum PreviewStatus { waitingForEngine, loading, loaded, failed }

final class const MediaPreviewState({
  final PreviewStatus previewStatus = .waitingForEngine,
  final MediaInfo? info,
  final MediaKind kind = .video,

  /// Index into `info.videoOptions`.
  final int optionIndex = 0,
  final AudioQuality audioQuality = .kbps320,
  final bool iphoneCompatible = true,
  final String? errorText,

  /// Photos: indexes into `info.postMedia` that will be downloaded.
  final Set<int> selectedImages = const {},
  final bool slideshowVideo = false,
  super.status,
  super.message,
}) extends BaseState {
  VideoOption? get selectedOption {
    final options = info?.videoOptions ?? const <VideoOption>[];
    return optionIndex < options.length ? options[optionIndex] : null;
  }

  /// TikTok slideshows can become one MP4 with their music.
  bool get canMakeSlideshow => (info?.musicUrl != null) && (info?.hasPhotos ?? false);

  /// Every chosen item is a photo (button reads "photos", not "items").
  bool get selectedAllPhotos =>
      [for (final index in selectedImages) ?info?.postMedia.elementAtOrNull(index)]
          .every((media) => media.kind == .photo);

  /// iPhone-compatible output for this quality means a slow re-encode.
  bool get needsReencode => kind == .video && iphoneCompatible && !(selectedOption?.hasH264 ?? true);

  /// Estimated download size of the current choice.
  int? get estimatedBytes => switch (kind) {
    .audio when info?.durationSeconds != null => info!.durationSeconds! * audioQuality.kbps * 1000 ~/ 8,
    .audio => null,
    _ => selectedOption?.sizeBytes,
  };

  MediaPreviewState copyWith({
    PreviewStatus? previewStatus,
    MediaInfo? info,
    MediaKind? kind,
    int? optionIndex,
    AudioQuality? audioQuality,
    bool? iphoneCompatible,
    String? errorText,
    Set<int>? selectedImages,
    bool? slideshowVideo,
    StateStatus? status,
    StateMessage? message,
  }) => MediaPreviewState(
    previewStatus: previewStatus ?? this.previewStatus,
    info: info ?? this.info,
    kind: kind ?? this.kind,
    optionIndex: optionIndex ?? this.optionIndex,
    audioQuality: audioQuality ?? this.audioQuality,
    iphoneCompatible: iphoneCompatible ?? this.iphoneCompatible,
    errorText: errorText,
    selectedImages: selectedImages ?? this.selectedImages,
    slideshowVideo: slideshowVideo ?? this.slideshowVideo,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [
    previewStatus,
    info,
    kind,
    optionIndex,
    audioQuality,
    iphoneCompatible,
    errorText,
    selectedImages,
    slideshowVideo,
    ...super.props,
  ];
}

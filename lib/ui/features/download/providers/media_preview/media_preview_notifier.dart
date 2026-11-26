import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/domain/models/audio_quality.dart';
import 'package:media_tool/domain/models/download_request.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/models/video_option.dart';
import 'package:media_tool/domain/use_cases/resolve_link_use_case.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/features/download/providers/engine_status/engine_status_notifier.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';

part 'media_preview_state.dart';

/// The preview sheet: resolves the link (engine probe or photo extractor)
/// once the engine is ready and holds the user's choices. AutoDispose: lives
/// as long as the sheet.
class MediaPreviewNotifier extends BaseNotifier<MediaPreviewState> {
  late final ResolveLinkUseCase _resolveLink;

  /// Settings → Downloads default; `null` is Best.
  int? _defaultResolution;
  bool _photosToJpg = true;
  ({String url, Site site})? _link;

  @override
  MediaPreviewState build() {
    _resolveLink = GetIt.I<ResolveLinkUseCase>();
    final settings = ref.read(settingsProvider).settings;
    _photosToJpg = settings.photosToJpg;
    _defaultResolution = settings.defaultVideoQuality.resolution;
    ref.listen(engineStatusProvider, (_, engine) {
      if (state.previewStatus == .waitingForEngine) {
        _probeWhenReady(engine);
      }
    });
    return MediaPreviewState(audioQuality: settings.defaultAudioQuality, iphoneCompatible: settings.iphoneCompatible);
  }

  /// Starts the preview for [url]; waits for the engine if it isn't ready.
  void start(String url, Site site) {
    _link = (url: url, site: site);
    _probeWhenReady(ref.read(engineStatusProvider));
  }

  Future<void> retry() async {
    final engine = ref.read(engineStatusProvider);
    if (engine.engineStatus == .failed) {
      state = state.copyWith(previewStatus: .waitingForEngine);
      await ref.read(engineStatusProvider.notifier).retry();
      return;
    }
    _probeWhenReady(engine);
  }

  void selectKind(MediaKind kind) => state = state.copyWith(kind: kind);

  void selectOption(int index) => state = state.copyWith(optionIndex: index);

  void selectAudioQuality(AudioQuality quality) => state = state.copyWith(audioQuality: quality);

  void setIphoneCompatible(bool value) => state = state.copyWith(iphoneCompatible: value);

  /// Photos: tap a tile to include or leave it out.
  void toggleImage(int index) {
    final selected = {...state.selectedImages};
    if (!selected.remove(index)) {
      selected.add(index);
    }
    state = state.copyWith(selectedImages: selected);
  }

  /// "Select all", or "Select none" when everything is selected.
  void toggleSelectAll() {
    final count = state.info?.postMedia.length ?? 0;
    final all = state.selectedImages.length == count;
    state = state.copyWith(selectedImages: all ? const {} : {for (var index = 0; index < count; index++) index});
  }

  /// TikTok slideshows: one MP4 with the music instead of separate photos.
  void setSlideshowVideo(bool value) => state = state.copyWith(slideshowVideo: value);

  /// The request for the current choices, or `null` before the probe finished.
  DownloadRequest? buildRequest() {
    final info = state.info;
    if (info == null) {
      return null;
    }
    if (state.kind == .photo) {
      return _postRequest(info);
    }
    final option = state.kind == .video ? state.selectedOption : null;
    return DownloadRequest(
      url: info.url,
      site: info.site,
      title: info.title,
      kind: state.kind,
      uploader: info.uploader,
      thumbnailUrl: info.thumbnailUrl,
      durationSeconds: info.durationSeconds,
      height: option?.height,
      resolution: option?.resolution,
      audioQuality: state.audioQuality,
      iphoneCompatible: state.iphoneCompatible,
      needsReencode: state.needsReencode,
      expectedBytes: state.estimatedBytes,
    );
  }

  /// The chosen items of a photo post, downloaded directly.
  DownloadRequest? _postRequest(MediaInfo info) {
    final media = [
      for (final (index, item) in info.postMedia.indexed)
        if (state.selectedImages.contains(index)) item,
    ];
    if (media.isEmpty) {
      return null;
    }
    final slideshow = state.canMakeSlideshow && state.slideshowVideo;
    return DownloadRequest(
      url: info.url,
      site: info.site,
      title: info.title,
      kind: slideshow || media.every((item) => item.kind == .video) ? .video : .photo,
      uploader: info.uploader,
      thumbnailUrl: media.first.previewUrl ?? info.thumbnailUrl,
      media: media,
      postId: info.postId,
      photosToJpg: _photosToJpg,
      slideshowVideo: slideshow,
      musicUrl: slideshow ? info.musicUrl : null,
    );
  }

  void _probeWhenReady(EngineStatusState engine) {
    final site = _link?.site;
    switch (engine.engineStatus) {
      case .initializing:
        state = state.copyWith(previewStatus: .waitingForEngine);
      // Photo posts and Threads don't need the engine.
      case .failed when site != null && _resolveLink.worksWithoutEngine(site):
        _resolve(useEngine: false);
      case .failed:
        state = state.copyWith(previewStatus: .failed, errorText: engine.errorText);
      case .ready:
        _resolve();
    }
  }

  Future<void> _resolve({bool useEngine = true}) => runFlow('download.probe', () async {
    final link = _link;
    if (link == null) {
      return;
    }
    state = state.copyWith(previewStatus: .loading);
    final result = await _resolveLink.run(link.url, useEngine: useEngine);
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case SuccessState(:final data?):
        state = state.copyWith(
          previewStatus: .loaded,
          info: data,
          kind: data.hasVideo
              ? .video
              : data.hasPostMedia
              ? .photo
              : .audio,
          optionIndex: _defaultOptionIndex(data.videoOptions),
          selectedImages: {for (var index = 0; index < data.postMedia.length; index++) index},
        );
      default:
        state = state.copyWith(previewStatus: .failed, errorText: trackFailure(result).text);
    }
  });

  /// The highest quality at or below the default, else Best (option 0).
  int _defaultOptionIndex(List<VideoOption> options) {
    final maxResolution = _defaultResolution;
    if (maxResolution == null) {
      return 0;
    }
    final index = options.indexWhere((option) => option.height != null && (option.resolution ?? 0) <= maxResolution);
    return index < 0 ? 0 : index;
  }
}

final mediaPreviewProvider = NotifierProvider.autoDispose(MediaPreviewNotifier.new);

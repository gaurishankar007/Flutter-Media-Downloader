import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_downloader/ui/core/ui/base/form/segmented_picker.dart';
import 'package:media_downloader/ui/core/ui/base/sheets/app_bottom_sheet.dart';
import 'package:media_downloader/ui/core/ui/base/states/error_state.dart';
import 'package:media_downloader/ui/features/download/providers/download_queue/download_queue_notifier.dart';
import 'package:media_downloader/ui/features/download/providers/media_preview/media_preview_notifier.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/audio_quality_chips.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/photo_selection_grid.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/preview_header.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/preview_loading.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/reencode_hint.dart';
import 'package:media_downloader/ui/features/download/views/preview/widgets/video_quality_chips.dart';

/// The bottom sheet after Preview: what the link is, Video / Audio / Photos,
/// quality or the photos to keep, iPhone-compatible, and Download. Pops `true` once a download is queued.
class const MediaPreviewSheet({super.key, required final String url, required final Site site})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaPreviewProvider);
    final notifier = ref.read(mediaPreviewProvider.notifier);

    useEffect(() {
      // After the first frame: providers can't change during build.
      Future.microtask(() => notifier.start(url, site));
      return null;
    }, const []);

    final info = state.info;
    if (state.previewStatus == .failed || (state.previewStatus == .loaded && info == null)) {
      return AppBottomSheet(
        child: ErrorState(message: state.errorText ?? CommonMessages.genericError, onRetry: notifier.retry),
      );
    }
    if (info == null || state.previewStatus != .loaded) {
      return AppBottomSheet(child: PreviewLoading(waitingForEngine: state.previewStatus == .waitingForEngine));
    }

    void download() {
      final request = notifier.buildRequest();
      if (request == null) {
        return;
      }
      ref.read(downloadQueueProvider.notifier).enqueue(request);
      Navigator.of(context).pop(true);
    }

    final size = state.estimatedBytes;
    final kinds = [
      if (info.hasVideo) (value: MediaKind.video, label: DownloadMessages.video, icon: Symbols.movie_rounded),
      if (info.hasVideo && info.hasAudio)
        (value: MediaKind.audio, label: DownloadMessages.audio, icon: Symbols.music_note_rounded),
      if (info.hasPostMedia)
        (value: MediaKind.photo, label: DownloadMessages.photos, icon: Symbols.photo_library_rounded),
    ];

    return AppBottomSheet(
      bottomAction: state.kind == .photo
          ? GradientButton(
              label: state.slideshowVideo && state.canMakeSlideshow
                  ? DownloadMessages.download(null)
                  : DownloadMessages.downloadPhotos(state.selectedImages.length, allPhotos: state.selectedAllPhotos),
              icon: Symbols.download_rounded,
              expand: true,
              onPressed: state.selectedImages.isEmpty ? null : download,
            )
          : GradientButton(
              label: DownloadMessages.download(size == null ? null : FormatUtils.bytes(size)),
              icon: Symbols.download_rounded,
              expand: true,
              onPressed: download,
            ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.lg,
        children: [
          PreviewHeader(info: info),
          if (kinds.length > 1)
            SegmentedPicker<MediaKind>(segments: kinds, selected: state.kind, onSelected: notifier.selectKind),
          if (state.kind == .photo) ...[
            PhotoSelectionGrid(
              media: info.postMedia,
              selected: state.selectedImages,
              onToggle: notifier.toggleImage,
              onToggleAll: notifier.toggleSelectAll,
            ),
            if (state.canMakeSlideshow)
              AppSwitchTile(
                title: DownloadMessages.slideshowVideo,
                subtitle: DownloadMessages.slideshowVideoBody,
                icon: Symbols.slideshow_rounded,
                value: state.slideshowVideo,
                onChanged: notifier.setSlideshowVideo,
              ),
          ] else if (state.kind == .video) ...[
            VideoQualityChips(
              options: info.videoOptions,
              selectedIndex: state.optionIndex,
              onSelected: notifier.selectOption,
            ),
            AppSwitchTile(
              title: SettingsMessages.iphoneCompatible,
              subtitle: SettingsMessages.iphoneCompatibleBody,
              icon: Symbols.phone_iphone_rounded,
              value: state.iphoneCompatible,
              onChanged: notifier.setIphoneCompatible,
            ),
            if (state.needsReencode) const ReencodeHint(),
          ] else
            AudioQualityChips(selected: state.audioQuality, onSelected: notifier.selectAudioQuality),
        ],
      ),
    );
  }
}

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/cards/job_card.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';

class const GalleryJobsSection({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final finished = useState(false);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(
          title: DesignGalleryMessages.jobs,
          trailing: GhostButton(
            label: finished.value ? DesignGalleryMessages.resetJob : DesignGalleryMessages.finishJob,
            onPressed: () => finished.value = !finished.value,
          ),
        ),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.md,
          children: [
            JobCard(
              title: DesignGalleryMessages.sampleTitle,
              kind: MediaKind.video,
              site: Site.youtube,
              stage: finished.value ? .done : .downloading,
              progress: 0.64,
              status: finished.value ? null : DesignGalleryMessages.sampleStatus,
              detail: finished.value ? DesignGalleryMessages.sampleDone : DesignGalleryMessages.sampleDetail,
              actions: finished.value
                  ? [
                      TonalButton(label: CommonMessages.share, icon: Symbols.ios_share_rounded, onPressed: () {}),
                      AppIconButton(
                        icon: Symbols.delete_rounded,
                        label: CommonMessages.remove,
                        destructive: true,
                        onPressed: () {},
                      ),
                    ]
                  : [AppIconButton(icon: Symbols.close_rounded, label: JobStageMessages.cancelJob, onPressed: () {})],
            ),
            const JobCard(
              title: DesignGalleryMessages.sampleTitleShort,
              kind: MediaKind.video,
              site: Site.tiktok,
              stage: .processing,
              progress: 0.3,
              detail: DesignGalleryMessages.sampleDetail,
            ),
            const JobCard(
              title: DesignGalleryMessages.sampleTitleShort,
              kind: MediaKind.audio,
              site: Site.instagram,
              stage: .queued,
            ),
            const JobCard(
              title: DesignGalleryMessages.sampleTitleShort,
              kind: MediaKind.video,
              site: Site.x,
              stage: .failed,
              detail: DesignGalleryMessages.sampleError,
            ),
          ],
        ),
      ],
    );
  }
}

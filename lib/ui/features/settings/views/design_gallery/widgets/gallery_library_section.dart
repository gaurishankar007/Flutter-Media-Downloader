import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/media_kind.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_tool/ui/core/ui/base/cards/media_card.dart';
import 'package:media_tool/ui/core/ui/base/media/photo_grid.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';

const _cards = [
  (kind: MediaKind.video, site: Site.youtube, meta: DesignGalleryMessages.sampleDone, saved: true),
  (kind: MediaKind.audio, site: Site.facebook, meta: DesignGalleryMessages.sampleAudio, saved: false),
  (kind: MediaKind.photo, site: Site.instagram, meta: '1080 × 1350 · 1.1 MB', saved: false),
  (kind: MediaKind.video, site: Site.threads, meta: DesignGalleryMessages.sampleDone, saved: true),
];

class const GalleryLibrarySection({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selected = useState<Set<int>>({0, 1, 2, 3, 4, 5});
    void toggle(int index) => selected.value = selected.value.contains(index)
        ? ({...selected.value}..remove(index))
        : {...selected.value, index};
    final allSelected = selected.value.length == 6;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: DesignGalleryMessages.library),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: .zero,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.92,
          children: [
            for (final card in _cards)
              MediaCard(
                title: DesignGalleryMessages.sampleTitle,
                kind: card.kind,
                site: card.site,
                metadata: card.meta,
                saved: card.saved,
                duration: card.kind == .photo ? null : DesignGalleryMessages.sampleDuration,
                onTap: () {},
              ),
          ],
        ),
        SectionHeader(
          title: DesignGalleryMessages.photoGrid,
          trailing: GhostButton(
            label: allSelected ? CommonMessages.selectNone : CommonMessages.selectAll,
            onPressed: () => selected.value = allSelected ? {} : {0, 1, 2, 3, 4, 5},
          ),
        ),
        PhotoGrid(photos: List.filled(6, null), selected: selected.value, onToggle: toggle),
        const SizedBox(height: AppSpacing.lg),
        GradientButton(
          label: DesignGalleryMessages.selectedCount(selected.value.length),
          expand: true,
          onPressed: selected.value.isEmpty ? null : () {},
        ),
      ],
    );
  }
}

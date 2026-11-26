import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/job_stage.dart';
import 'package:media_downloader/domain/models/media_kind.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';
import 'package:media_downloader/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_slider.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_downloader/ui/core/ui/base/form/segmented_picker.dart';
import 'package:media_downloader/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_downloader/ui/core/ui/base/progress/stage_label.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';

const _qualities = ['Best', '4K · 1.2 GB', '1080p · 310 MB', '720p · 140 MB', '480p · 70 MB'];

class const GalleryControlsSection({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final kind = useState(MediaKind.video);
    final quality = useState(2);
    final iphone = useState(true);
    final slider = useState(0.6);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: DesignGalleryMessages.buttons),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: .center,
          children: [
            GradientButton(label: DesignGalleryMessages.primary, icon: Symbols.download_rounded, onPressed: () {}),
            const GradientButton(label: DesignGalleryMessages.primary),
            TonalButton(label: DesignGalleryMessages.secondary, icon: Symbols.photo_library_rounded, onPressed: () {}),
            TonalButton(label: CommonMessages.delete, destructive: true, onPressed: () {}),
            GhostButton(label: DesignGalleryMessages.tertiary, onPressed: () {}),
            AppIconButton(icon: Symbols.ios_share_rounded, label: CommonMessages.share, onPressed: () {}),
            AppIconButton(
              icon: Symbols.delete_rounded,
              label: CommonMessages.remove,
              destructive: true,
              onPressed: () {},
            ),
          ],
        ),
        const SectionHeader(title: DesignGalleryMessages.controls),
        AppCard(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: AppSpacing.lg,
            children: [
              SegmentedPicker<MediaKind>(
                segments: const [
                  (value: .video, label: DesignGalleryMessages.video, icon: Symbols.movie_rounded),
                  (value: .audio, label: DesignGalleryMessages.audio, icon: Symbols.music_note_rounded),
                  (value: .photo, label: DesignGalleryMessages.photos, icon: Symbols.image_rounded),
                ],
                selected: kind.value,
                onSelected: (value) => kind.value = value,
              ),
              ChipRow(
                children: [
                  for (final (index, label) in _qualities.indexed)
                    SelectChip(label: label, selected: quality.value == index, onSelected: () => quality.value = index),
                ],
              ),
              AppSwitchTile(
                title: SettingsMessages.iphoneCompatible,
                subtitle: SettingsMessages.iphoneCompatibleBody,
                icon: Symbols.phone_iphone_rounded,
                value: iphone.value,
                onChanged: (value) => iphone.value = value,
              ),
              AppSlider(
                label: DesignGalleryMessages.quality,
                valueLabel: '${(slider.value * 100).round()}%',
                value: slider.value,
                divisions: 20,
                onChanged: (value) => slider.value = value,
              ),
            ],
          ),
        ),
        const SectionHeader(title: DesignGalleryMessages.progress),
        AppCard(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: AppSpacing.md,
            children: [
              GradientProgressBar(value: slider.value),
              const GradientProgressBar(),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [for (final stage in JobStage.values) StageLabel(stage: stage)],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

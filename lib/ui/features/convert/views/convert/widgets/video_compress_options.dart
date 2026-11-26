import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/video_compress_preset.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_slider.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_options/convert_options_notifier.dart';

/// Compress video: preset, max resolution and "aim for about N MB".
class const VideoCompressOptionsPanel({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertOptionsProvider);
    final notifier = ref.read(convertOptionsProvider.notifier);
    final options = state.options;
    final targetMb = options.targetMb;
    final tooLow = state.request?.targetTooLow ?? false;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: ConvertMessages.preset),
        ChipRow(
          wrap: true,
          children: [
            for (final preset in VideoCompressPreset.values)
              SelectChip(
                label: switch (preset) {
                  .high => ConvertMessages.presetHigh,
                  .medium => ConvertMessages.presetMedium,
                  .small => ConvertMessages.presetSmall,
                },
                selected: preset == options.preset,
                onSelected: () => notifier.setPreset(preset),
              ),
          ],
        ),
        if (state.heights.isNotEmpty) ...[
          const SectionHeader(title: ConvertMessages.maxResolution),
          ChipRow(
            wrap: true,
            children: [
              SelectChip(
                label: ConvertMessages.original,
                selected: options.maxHeight == null,
                onSelected: () => notifier.setHeight(null),
              ),
              for (final height in state.heights)
                SelectChip(
                  label: ConvertMessages.resolution(height),
                  selected: options.maxHeight == height,
                  onSelected: () => notifier.setHeight(height),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.lg,
          children: [
            AppSwitchTile(
              title: ConvertMessages.aimForSize,
              icon: Symbols.straighten_rounded,
              value: targetMb != null,
              onChanged: (on) => notifier.toggleTargetMb(on: on),
            ),
            if (targetMb != null)
              AppSlider(
                label: ConvertMessages.aimForSize,
                valueLabel: ConvertMessages.aboutMb(targetMb),
                value: targetMb.toDouble(),
                min: 1,
                max: state.maxTargetMb.toDouble(),
                onChanged: (value) => notifier.setTargetMb(value.round()),
              ),
            if (tooLow)
              Text(ConvertMessages.targetTooLow, style: context.text.label.copyWith(color: context.colors.warning)),
          ],
        ),
      ],
    );
  }
}

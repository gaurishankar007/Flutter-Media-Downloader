import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_tool/ui/core/ui/base/form/app_slider.dart';
import 'package:media_tool/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/convert/providers/convert_options/convert_options_notifier.dart';

/// Compress image: longest side or a percentage, quality, strip metadata.
class const ImageCompressOptionsPanel({super.key}) extends ConsumerWidget {
  static const _percents = [75, 50, 25];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertOptionsProvider);
    final notifier = ref.read(convertOptionsProvider.notifier);
    final image = state.options.image;
    final format = state.compressFormat;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: ConvertMessages.imageSize),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.lg,
          children: [
            ChipRow(
              wrap: true,
              children: [
                SelectChip(
                  label: ConvertMessages.original,
                  selected: image.longestSide == null && image.percent == null,
                  onSelected: notifier.setImageSize,
                ),
                for (final side in state.imageSides)
                  SelectChip(
                    label: ConvertMessages.pixels(side),
                    selected: image.longestSide == side,
                    onSelected: () => notifier.setImageSize(longestSide: side),
                  ),
                if (state.source?.longSide != null)
                  for (final percent in _percents)
                    SelectChip(
                      label: ConvertMessages.percent(percent),
                      selected: image.percent == percent,
                      onSelected: () => notifier.setImageSize(percent: percent),
                    ),
              ],
            ),
            // PNG is lossless: quality doesn't apply.
            if (format != .png)
              AppSlider(
                label: ConvertMessages.imageQuality,
                valueLabel: '${image.quality}',
                value: image.quality.toDouble(),
                min: 40,
                max: 100,
                divisions: 12,
                onChanged: (value) => notifier.setImageQuality(value.round()),
              ),
            AppSwitchTile(
              title: ConvertMessages.stripMetadata,
              subtitle: ConvertMessages.stripMetadataBody,
              icon: Symbols.location_off_rounded,
              value: image.stripMetadata,
              onChanged: (strip) => notifier.setStripMetadata(strip: strip),
            ),
            if (format != null)
              Text(
                ConvertMessages.outputFormat(format.label),
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
          ],
        ),
      ],
    );
  }
}

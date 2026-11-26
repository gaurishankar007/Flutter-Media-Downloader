import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_downloader/ui/core/ui/base/form/app_switch_tile.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_options/convert_options_notifier.dart';

/// Convert: the formats valid for the file, and the iPhone-compatible switch
/// when an MP4 / MOV would otherwise keep codecs the iPhone can't play.
class const FormatChips({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertOptionsProvider);
    final notifier = ref.read(convertOptionsProvider.notifier);
    final format = state.options.format;
    final source = state.source;
    if (state.targets.isEmpty) {
      return Text(ConvertMessages.noTargets, style: context.text.body.copyWith(color: context.colors.textSecondary));
    }
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: ConvertMessages.convertTo),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.lg,
          children: [
            ChipRow(
              wrap: true,
              children: [
                for (final target in state.targets)
                  SelectChip(
                    label: target.label,
                    selected: target == format,
                    onSelected: () => notifier.setFormat(target),
                  ),
              ],
            ),
            if ((format == .mp4 || format == .mov) && source != null && !source.hasIphoneVideo)
              AppSwitchTile(
                title: ConvertMessages.iphoneCompatible,
                subtitle: ConvertMessages.iphoneCompatibleBody,
                value: state.options.iphoneCompatible,
                onChanged: (on) => notifier.setIphoneCompatible(on: on),
              ),
          ],
        ),
      ],
    );
  }
}

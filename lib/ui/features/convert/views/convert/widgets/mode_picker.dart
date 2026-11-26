import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/convert_mode.dart';
import 'package:media_downloader/ui/core/ui/base/form/segmented_picker.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_options/convert_options_notifier.dart';

/// Convert / Compress. Hidden by the screen when the file can't be compressed.
class const ModePicker({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(convertOptionsProvider.select((state) => state.options.mode));
    return SegmentedPicker<ConvertMode>(
      segments: const [
        (value: .convert, label: ConvertMessages.convertMode, icon: Symbols.swap_horiz_rounded),
        (value: .compress, label: ConvertMessages.compressMode, icon: Symbols.compress_rounded),
      ],
      selected: mode,
      onSelected: ref.read(convertOptionsProvider.notifier).setMode,
    );
  }
}

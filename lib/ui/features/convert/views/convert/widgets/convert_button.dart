import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_job/convert_job_notifier.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_options/convert_options_notifier.dart';

/// Starts the job: "Convert · about 48 MB".
class const ConvertButton({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(convertOptionsProvider.select((state) => state.request));
    final size = switch (request?.estimatedBytes) {
      final bytes? when bytes > 0 => FormatUtils.bytes(bytes),
      _ => null,
    };
    final compress = request?.isCompress ?? false;
    return GradientButton(
      label: compress ? ConvertMessages.compressButton(size) : ConvertMessages.convertButton(size),
      icon: compress ? Symbols.compress_rounded : Symbols.swap_horiz_rounded,
      expand: true,
      onPressed: request == null ? null : () => ref.read(convertJobProvider.notifier).start(request),
    );
  }
}

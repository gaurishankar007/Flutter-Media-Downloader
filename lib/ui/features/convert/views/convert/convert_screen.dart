import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_downloader/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';
import 'package:media_downloader/ui/core/utils/extensions/ref_extension.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_job/convert_job_notifier.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_options/convert_options_notifier.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_source/convert_source_notifier.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/convert_button.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/convert_job_panel.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/convert_result_section.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/format_chips.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/format_overview_card.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/image_compress_options.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/mode_picker.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/result_actions.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/source_preview.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/source_tiles.dart';
import 'package:media_downloader/ui/features/convert/views/convert/widgets/video_compress_options.dart';

/// Pick a file → convert or compress → result, in one screen.
/// See docs/features/convert.md.
@RoutePage()
class const ConvertScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(convertSourceProvider.select((state) => state.source));
    final job = ref.watch(convertJobProvider.select((state) => (hasJob: state.request != null, done: state.isDone)));
    final options = ref.watch(
      convertOptionsProvider.select((state) => (mode: state.options.mode, canCompress: state.canCompress)),
    );
    final sourceNotifier = ref.read(convertSourceProvider.notifier);

    ref
      ..listenMessages(convertSourceProvider, context)
      ..listenMessages(convertJobProvider, context);

    void done() {
      ref.read(convertJobProvider.notifier).reset();
      sourceNotifier.clear();
    }

    final picking = !job.hasJob && source != null;
    return ScreenScrollView(
      // Convert, or the result's Save / Share / Done, stays at the bottom.
      bottomAction: switch ((job.hasJob, job.done)) {
        (true, true) => ResultActions(onDone: done),
        _ when picking => const ConvertButton(),
        _ => null,
      },
      children: [
        const ScreenHeader(title: ConvertMessages.title, subtitle: ConvertMessages.subtitle),
        if (job.hasJob)
          if (job.done) const ConvertResultSection() else const ConvertJobPanel()
        else if (source == null) ...[
          const SectionHeader(title: ConvertMessages.pickFile),
          const SourceTiles(),
          const SectionHeader(title: ConvertMessages.whatYouCanDo),
          const FormatOverviewCard(),
        ] else ...[
          SourcePreview(source: source, onChange: sourceNotifier.clear),
          if (options.canCompress) ...[const SectionHeader(title: ConvertMessages.whatToDo), const ModePicker()],
          switch ((options.mode, source.kind)) {
            (.convert, _) => const FormatChips(),
            (.compress, .photo) => const ImageCompressOptionsPanel(),
            (.compress, _) => const VideoCompressOptionsPanel(),
          },
        ],
      ],
    );
  }
}

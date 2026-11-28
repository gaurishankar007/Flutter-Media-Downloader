import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/compress_pdf_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/edit_image_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/images_to_gif_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/images_to_pdf_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/organize_pages_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/pdf_to_images_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/resize_image_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/split_pdf_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/unlock_pdf_options.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/video_part_options.dart';

/// [tool]'s own options, and why it can't start yet when the user can fix it.
class const ToolOptions({super.key, required final Tool tool}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(toolOptionsProvider(tool).select((state) => state.problem));
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        switch (tool) {
          .imagesToPdf => const ImagesToPdfOptions(),
          .pdfToImages => const PdfToImagesOptions(),
          .splitPdf => const SplitPdfOptions(),
          .organizePdf => const OrganizePagesOptions(),
          .compressPdf => const CompressPdfOptions(),
          .unlockPdf => const UnlockPdfOptions(),
          .videoToGif || .trimVideo => VideoPartOptions(tool: tool),
          .imagesToGif => const ImagesToGifOptions(),
          .resizeImage => const ResizeImageOptions(),
          .editImage => const EditImageOptions(),
          .mergePdf || .gifToVideo || .muteVideo => const SizedBox.shrink(),
        },
        if (problem != null) OptionNote(text: problem, warning: true),
      ],
    );
  }
}

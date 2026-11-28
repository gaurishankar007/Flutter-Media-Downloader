import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/library/models/library_entry.dart';
import 'package:pdfrx/pdfrx.dart';

/// A PDF's pages, scrolled vertically and zoomable (PDFium).
class const DocumentViewer({super.key, required final LibraryEntry entry}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PdfViewer.file(
      entry.filePath,
      params: PdfViewerParams(
        backgroundColor: context.colors.background,
        // The file was removed outside the app, or PDFium can't read it.
        errorBannerBuilder: (context, _, _, _) => Center(
          child: Column(
            mainAxisSize: .min,
            spacing: AppSpacing.sm,
            children: [
              Icon(Symbols.broken_image_rounded, color: context.colors.textMuted),
              Text(
                LibraryMessages.cantOpenPdf,
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

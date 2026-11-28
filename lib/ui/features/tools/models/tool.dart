import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/domain/models/tool_input.dart';
import 'package:media_tool/ui/features/tools/models/tool_category.dart';

/// One tool of the Tools tab: its card, what it takes and its start button.
/// See docs/features/tools.md#tools.
enum Tool {
  imagesToPdf(
    category: .pdf,
    icon: Symbols.picture_as_pdf_rounded,
    title: ToolsMessages.imagesToPdf,
    body: ToolsMessages.imagesToPdfBody,
    input: .images,
    multiple: true,
    startLabel: ToolsMessages.makePdf,
  ),
  pdfToImages(
    category: .pdf,
    icon: Symbols.photo_library_rounded,
    title: ToolsMessages.pdfToImages,
    body: ToolsMessages.pdfToImagesBody,
    input: .pdf,
    startLabel: ToolsMessages.saveImages,
  ),
  mergePdf(
    category: .pdf,
    icon: Symbols.merge_rounded,
    title: ToolsMessages.mergePdf,
    body: ToolsMessages.mergePdfBody,
    input: .pdf,
    multiple: true,
    minSources: 2,
    startLabel: ToolsMessages.merge,
  ),
  splitPdf(
    category: .pdf,
    icon: Symbols.call_split_rounded,
    title: ToolsMessages.splitPdf,
    body: ToolsMessages.splitPdfBody,
    input: .pdf,
    startLabel: ToolsMessages.split,
  ),
  organizePdf(
    category: .pdf,
    icon: Symbols.view_module_rounded,
    title: ToolsMessages.organizePdf,
    body: ToolsMessages.organizePdfBody,
    input: .pdf,
    startLabel: ToolsMessages.savePdf,
  ),
  compressPdf(
    category: .pdf,
    icon: Symbols.compress_rounded,
    title: ToolsMessages.compressPdf,
    body: ToolsMessages.compressPdfBody,
    input: .pdf,
    startLabel: ToolsMessages.compress,
  ),
  unlockPdf(
    category: .pdf,
    icon: Symbols.lock_open_rounded,
    title: ToolsMessages.unlockPdf,
    body: ToolsMessages.unlockPdfBody,
    input: .pdf,
    startLabel: ToolsMessages.unlock,
  ),
  videoToGif(
    category: .gifVideo,
    icon: Symbols.gif_box_rounded,
    title: ToolsMessages.videoToGif,
    body: ToolsMessages.videoToGifBody,
    input: .video,
    startLabel: ToolsMessages.makeGif,
  ),
  imagesToGif(
    category: .gifVideo,
    icon: Symbols.animated_images_rounded,
    title: ToolsMessages.imagesToGif,
    body: ToolsMessages.imagesToGifBody,
    input: .images,
    multiple: true,
    minSources: 2,
    startLabel: ToolsMessages.makeGif,
  ),
  gifToVideo(
    category: .gifVideo,
    icon: Symbols.movie_rounded,
    title: ToolsMessages.gifToVideo,
    body: ToolsMessages.gifToVideoBody,
    input: .gif,
    startLabel: ToolsMessages.makeVideo,
  ),
  trimVideo(
    category: .gifVideo,
    icon: Symbols.content_cut_rounded,
    title: ToolsMessages.trimVideo,
    body: ToolsMessages.trimVideoBody,
    input: .video,
    startLabel: ToolsMessages.trim,
  ),
  muteVideo(
    category: .gifVideo,
    icon: Symbols.volume_off_rounded,
    title: ToolsMessages.muteVideo,
    body: ToolsMessages.muteVideoBody,
    input: .video,
    startLabel: ToolsMessages.mute,
  ),
  resizeImage(
    category: .image,
    icon: Symbols.photo_size_select_large_rounded,
    title: ToolsMessages.resizeImage,
    body: ToolsMessages.resizeImageBody,
    input: .images,
    startLabel: ToolsMessages.resize,
  ),
  editImage(
    category: .image,
    icon: Symbols.crop_rotate_rounded,
    title: ToolsMessages.editImage,
    body: ToolsMessages.editImageBody,
    input: .images,
    startLabel: ToolsMessages.saveImage,
  );

  new({
    required this.category,
    required this.icon,
    required this.title,
    required this.body,
    required this.input,
    required this.startLabel,
    this.multiple = false,
    this.minSources = 1,
  });

  final ToolCategory category;
  final IconData icon;
  final String title;
  final String body;
  final ToolInput input;
  final String startLabel;

  /// Takes several files (in the user's order).
  final bool multiple;
  final int minSources;

  /// What From Files offers.
  String get filesBody => switch (input) {
    .images => ToolsMessages.filesImagesBody,
    .pdf => ToolsMessages.filesPdfBody,
    .video => ToolsMessages.filesVideoBody,
    .gif => ToolsMessages.filesGifBody,
  };

  /// Photos can only hold images and videos.
  bool get canPickFromPhotos => input == .images || input == .video;
}

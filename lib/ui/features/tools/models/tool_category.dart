import 'package:media_tool/core/messages/app_messages.dart';

/// The Tools hub's sections, in order.
enum ToolCategory {
  pdf(ToolsMessages.categoryPdf),
  gifVideo(ToolsMessages.categoryGifVideo),
  image(ToolsMessages.categoryImage);

  new(this.label);

  final String label;
}

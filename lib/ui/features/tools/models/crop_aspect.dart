import 'package:media_tool/core/messages/app_messages.dart';

/// Rotate & crop's crop presets (width / height); [original] doesn't crop.
enum CropAspect {
  original(null, ToolsMessages.cropOriginal),
  square(1, ToolsMessages.cropSquare),
  portrait(4 / 5, ToolsMessages.cropPortrait),
  photo(3 / 2, ToolsMessages.cropPhoto),
  wide(16 / 9, ToolsMessages.cropWide),
  story(9 / 16, ToolsMessages.cropStory);

  new(this.ratio, this.label);

  final double? ratio;
  final String label;
}

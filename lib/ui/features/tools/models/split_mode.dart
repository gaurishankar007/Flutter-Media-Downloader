import 'package:media_tool/core/messages/app_messages.dart';

/// How Split PDF cuts the document.
enum SplitMode {
  each(ToolsMessages.splitEach),
  every(ToolsMessages.splitEvery),
  ranges(ToolsMessages.splitRanges);

  new(this.label);

  final String label;
}

import 'package:media_tool/core/messages/app_messages.dart';

/// The Library's sort order.
enum LibrarySort {
  newest(LibraryMessages.sortNewest),
  oldest(LibraryMessages.sortOldest),
  largest(LibraryMessages.sortLargest);

  new(this.label);

  final String label;
}

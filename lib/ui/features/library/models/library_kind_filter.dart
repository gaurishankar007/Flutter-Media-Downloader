import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';

/// The Library's kind filter chips.
enum LibraryKindFilter {
  all(Symbols.apps_rounded, LibraryMessages.all),
  videos(Symbols.movie_rounded, LibraryMessages.videos),
  audio(Symbols.music_note_rounded, LibraryMessages.audio),
  photos(Symbols.image_rounded, LibraryMessages.photos),
  documents(Symbols.picture_as_pdf_rounded, LibraryMessages.documents);

  new(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// What a tool takes as input; decides the pickers' filters and which Library
/// items it offers. See docs/features/tools.md.
enum ToolInput {
  images({'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'bmp'}),
  pdf({'pdf'}),
  video({'mp4', 'mov', 'm4v', 'mkv', 'webm', 'avi', '3gp'}),
  gif({'gif'});

  new(this.extensions);

  /// Lower-case file extensions this input accepts.
  final Set<String> extensions;
}

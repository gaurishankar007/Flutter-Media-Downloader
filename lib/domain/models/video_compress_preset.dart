/// Video compression presets. Starting values from docs/engine/ffmpeg_recipes.md#compress-video.
enum VideoCompressPreset {
  high(crf: 23, toolboxQuality: 65, kbps1080: 6000, kbps720: 3500, kbps480: 1800, audioKbps: 160),
  medium(crf: 28, toolboxQuality: 55, kbps1080: 4000, kbps720: 2500, kbps480: 1200, audioKbps: 128),
  small(crf: 32, toolboxQuality: 45, kbps1080: 2500, kbps720: 1500, kbps480: 800, audioKbps: 96);

  new({
    required this.crf,
    required this.toolboxQuality,
    required this.kbps1080,
    required this.kbps720,
    required this.kbps480,
    required this.audioKbps,
  });

  /// libx264 `-crf`.
  final int crf;

  /// videotoolbox `-q:v`.
  final int toolboxQuality;
  final int kbps1080;
  final int kbps720;
  final int kbps480;

  /// AAC audio bitrate.
  final int audioKbps;

  /// Video bitrate for encoders that need one (mediacodec), by the output's
  /// short side. Above 1080p it grows with the pixel count.
  int videoKbps(int height) => switch (height) {
    > 1080 => (kbps1080 * (height * height) / (1080 * 1080)).round(),
    >= 900 => kbps1080,
    >= 600 => kbps720,
    _ => kbps480,
  };
}

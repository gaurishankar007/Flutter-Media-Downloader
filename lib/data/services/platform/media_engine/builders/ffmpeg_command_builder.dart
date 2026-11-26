/// Builds every ffmpeg command line. See docs/engine/ffmpeg_recipes.md.
abstract final class FfmpegCommandBuilder {
  /// Video encoders to try for an iPhone-compatible MP4, best first, from
  /// what the engine reported. libx264 is always last as the safe fallback.
  static List<String> iphoneEncoders(List<String> available) => [
    for (final encoder in ['hevc_videotoolbox', 'hevc_mediacodec', 'h264_videotoolbox'])
      if (available.contains(encoder)) encoder,
    'libx264',
  ];

  /// Re-encode to an MP4 the iPhone Photos app plays: HEVC (`hvc1` tag) or
  /// H.264, AAC audio, faststart. Progress goes to stdout (`out_time_us=`).
  static List<String> iphoneVideo({
    required String input,
    required String output,
    required String encoder,
    int? height,
  }) => [
    '-hide_banner',
    '-nostats',
    '-progress',
    'pipe:1',
    '-y',
    '-i',
    input,
    ...switch (encoder) {
      'hevc_videotoolbox' => ['-c:v', encoder, '-q:v', '65', '-tag:v', 'hvc1'],
      'hevc_mediacodec' => ['-c:v', encoder, '-b:v', _hevcBitrate(height), '-tag:v', 'hvc1'],
      'h264_videotoolbox' => ['-c:v', encoder, '-q:v', '65'],
      _ => ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23'],
    },
    '-pix_fmt',
    'yuv420p',
    '-c:a',
    'aac',
    '-b:a',
    '192k',
    '-movflags',
    '+faststart',
    output,
  ];

  /// TikTok slideshow → MP4: [imagePattern] (`/work/%02d.jpg`, numbered from
  /// 01) shown [secondsPerImage] each over the music, 1080×1920 with padding.
  /// See docs/engine/ffmpeg_recipes.md#tiktok-slideshow--video-optional.
  static List<String> slideshow({
    required String imagePattern,
    required String music,
    required String output,
    required String encoder,
    int secondsPerImage = 3,
  }) => [
    '-hide_banner',
    '-nostats',
    '-progress',
    'pipe:1',
    '-y',
    '-framerate',
    '1/$secondsPerImage',
    '-start_number',
    '1',
    '-i',
    imagePattern,
    '-i',
    music,
    '-vf',
    'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p',
    '-r',
    '30',
    ...switch (encoder) {
      'hevc_videotoolbox' => ['-c:v', encoder, '-q:v', '65', '-tag:v', 'hvc1'],
      'hevc_mediacodec' => ['-c:v', encoder, '-b:v', '6M', '-tag:v', 'hvc1'],
      'h264_videotoolbox' => ['-c:v', encoder, '-q:v', '65'],
      _ => ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23', '-tune', 'stillimage'],
    },
    '-c:a',
    'aac',
    '-b:a',
    '192k',
    '-shortest',
    '-movflags',
    '+faststart',
    output,
  ];

  /// Reads a local file: with no output ffmpeg prints the input's duration
  /// and streams to stderr and exits with an error (parsed by FfmpegInfoParser).
  static List<String> probe(String input) => ['-hide_banner', '-i', input];

  /// Convert to MP4 / MOV / MKV by copying the first video and audio stream.
  /// [hevcTag] marks HEVC `hvc1` for Apple; [aacAudio] re-encodes only the
  /// audio (when it isn't AAC and the container is MP4 / MOV).
  /// See docs/engine/ffmpeg_recipes.md#convert.
  static List<String> remux({
    required String input,
    required String output,
    bool hevcTag = false,
    bool aacAudio = false,
    bool faststart = false,
  }) => [
    ..._head(input),
    ..._firstStreams,
    '-c',
    'copy',
    if (hevcTag) ...['-tag:v', 'hvc1'],
    if (aacAudio) ...['-c:a', 'aac', '-b:a', '192k'],
    if (faststart) ...['-movflags', '+faststart'],
    output,
  ];

  /// Video → WebM (VP9 + Opus). Slow; only offered when libvpx-vp9 exists.
  static List<String> webm({required String input, required String output}) => [
    ..._head(input),
    ..._firstStreams,
    '-c:v',
    'libvpx-vp9',
    '-crf',
    '32',
    '-b:v',
    '0',
    '-row-mt',
    '1',
    '-c:a',
    'libopus',
    '-b:a',
    '128k',
    output,
  ];

  /// Video / audio → MP3 (best VBR), or → M4A ([copyAac] copies AAC audio as is).
  static List<String> audio({required String input, required String output, required bool mp3, bool copyAac = false}) =>
      [
        ..._head(input),
        '-vn',
        '-map',
        '0:a:0',
        ...switch ((mp3, copyAac)) {
          (true, _) => ['-c:a', 'libmp3lame', '-q:a', '0'],
          (false, true) => ['-c:a', 'copy', '-movflags', '+faststart'],
          (false, false) => ['-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart'],
        },
        output,
      ];

  /// Compress a video to MP4 with [encoder]: downscale to [scaleHeight] (short
  /// side; [portrait] scales the width), then [videoKbps] when aiming for a
  /// size, else the preset's quality ([crf] / [toolboxQuality] / [presetKbps]).
  /// See docs/engine/ffmpeg_recipes.md#compress-video.
  static List<String> compressVideo({
    required String input,
    required String output,
    required String encoder,
    required int crf,
    required int toolboxQuality,
    required int presetKbps,
    required int audioKbps,
    int? scaleHeight,
    bool portrait = false,
    int? videoKbps,
  }) {
    final rate = videoKbps ?? presetKbps;
    final bitrate = ['-b:v', '${rate}k', '-maxrate', '${(rate * 1.5).round()}k', '-bufsize', '${rate * 2}k'];
    return [
      ..._head(input),
      ..._firstStreams,
      if (scaleHeight != null) ...['-vf', 'scale=${portrait ? '$scaleHeight:-2' : '-2:$scaleHeight'}'],
      ...switch (encoder) {
        'hevc_videotoolbox' || 'h264_videotoolbox' => [
          '-c:v',
          encoder,
          if (videoKbps == null) ...['-q:v', '$toolboxQuality'] else ...bitrate,
        ],
        'hevc_mediacodec' => ['-c:v', encoder, ...bitrate],
        _ => [
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          if (videoKbps == null) ...['-crf', '$crf'] else ...bitrate,
        ],
      },
      if (encoder.startsWith('hevc')) ...['-tag:v', 'hvc1'],
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-b:a',
      '${audioKbps}k',
      '-movflags',
      '+faststart',
      output,
    ];
  }

  /// One frame at [atSeconds] as a 480px-wide JPG for the Library card.
  static List<String> thumbnail({required String input, required String output, required double atSeconds}) => [
    '-hide_banner',
    '-nostats',
    '-y',
    '-ss',
    atSeconds.toStringAsFixed(2),
    '-i',
    input,
    '-frames:v',
    '1',
    '-vf',
    'scale=480:-2',
    '-q:v',
    '4',
    output,
  ];

  static List<String> _head(String input) => ['-hide_banner', '-nostats', '-progress', 'pipe:1', '-y', '-i', input];

  // Subtitles and cover art often can't go into the new container.
  static const _firstStreams = ['-map', '0:v:0', '-map', '0:a:0?'];

  static String _hevcBitrate(int? height) => switch (height ?? 2160) {
    >= 2000 => '20M',
    >= 1400 => '12M',
    _ => '8M',
  };
}

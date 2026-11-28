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

  /// One image re-encoded as [format] (`jpg`, `png` or `webp`) at [quality]
  /// (1–100), its short side scaled down to [shortSide] (never up). Used on
  /// Windows and Linux, which have no system image encoder plugin.
  /// See docs/engine/ffmpeg_recipes.md#images.
  static List<String> image({
    required String input,
    required String output,
    required String format,
    required int quality,
    int? shortSide,
  }) => [
    '-hide_banner',
    '-nostats',
    '-y',
    '-i',
    input,
    if (shortSide != null) ...[
      '-vf',
      "scale='if(gt(iw,ih),-1,min($shortSide,iw))':'if(gt(iw,ih),min($shortSide,ih),-1)'",
    ],
    ...switch (format) {
      'png' => ['-c:v', 'png'],
      'webp' => ['-c:v', 'libwebp', '-quality', '$quality'],
      // mjpeg's -q:v runs 2 (best) to 31.
      _ => ['-c:v', 'mjpeg', '-q:v', '${(2 + (100 - quality.clamp(0, 100)) * 29 / 100).round()}'],
    },
    '-frames:v',
    '1',
    '-update',
    '1',
    output,
  ];

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

  /// A part of a video → animated GIF: [fps] frames a second, [width] wide,
  /// with a palette made from the clip itself (two-pass quality in one run).
  /// See docs/engine/ffmpeg_recipes.md#gif.
  static List<String> gifFromVideo({
    required String input,
    required String output,
    required double startSeconds,
    required double durationSeconds,
    required int fps,
    required int width,
  }) => [
    '-hide_banner',
    '-nostats',
    '-progress',
    'pipe:1',
    '-y',
    '-ss',
    startSeconds.toStringAsFixed(3),
    '-t',
    durationSeconds.toStringAsFixed(3),
    '-i',
    input,
    '-vf',
    'fps=$fps,scale=$width:-1:flags=lanczos,$_gifPalette',
    '-loop',
    '0',
    output,
  ];

  /// Numbered frames ([framePattern], `%03d.png` from 001, all the same size)
  /// → animated GIF showing each for [secondsPerImage].
  static List<String> gifFromFrames({
    required String framePattern,
    required String output,
    required double secondsPerImage,
  }) => [
    '-hide_banner',
    '-nostats',
    '-progress',
    'pipe:1',
    '-y',
    '-framerate',
    (1 / secondsPerImage).toStringAsFixed(4),
    '-start_number',
    '1',
    '-i',
    framePattern,
    '-vf',
    _gifPalette,
    '-loop',
    '0',
    output,
  ];

  /// One image fitted inside [width] × [height] on a white canvas (a GIF frame).
  static List<String> fitFrame({
    required String input,
    required String output,
    required int width,
    required int height,
  }) => [
    '-hide_banner',
    '-nostats',
    '-y',
    '-i',
    input,
    '-vf',
    [
      'scale=$width:$height:force_original_aspect_ratio=decrease:flags=lanczos',
      'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=white',
      'format=rgb24',
    ].join(','),
    '-frames:v',
    '1',
    '-update',
    '1',
    output,
  ];

  /// Animated GIF → MP4 with [encoder] (even dimensions, yuv420p, faststart).
  static List<String> gifToVideo({required String input, required String output, required String encoder}) => [
    ..._head(input),
    '-vf',
    'scale=trunc(iw/2)*2:trunc(ih/2)*2',
    ..._videoEncoder(encoder),
    '-pix_fmt',
    'yuv420p',
    '-an',
    '-movflags',
    '+faststart',
    output,
  ];

  /// Keep [startSeconds] + [durationSeconds] of a video. With no [encoder] the
  /// streams are copied (fast; the cut lands on keyframes), else re-encoded
  /// with it for a frame-exact cut.
  static List<String> trim({
    required String input,
    required String output,
    required double startSeconds,
    required double durationSeconds,
    String? encoder,
  }) => [
    '-hide_banner',
    '-nostats',
    '-progress',
    'pipe:1',
    '-y',
    '-ss',
    startSeconds.toStringAsFixed(3),
    '-i',
    input,
    '-t',
    durationSeconds.toStringAsFixed(3),
    ..._firstStreams,
    if (encoder == null) ...[
      '-c',
      'copy',
      '-avoid_negative_ts',
      'make_zero',
    ] else ...[
      ..._videoEncoder(encoder),
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
    ],
    '-movflags',
    '+faststart',
    output,
  ];

  /// The first video stream only, copied: the sound is gone.
  static List<String> mute({required String input, required String output}) => [
    ..._head(input),
    '-map',
    '0:v:0',
    '-c',
    'copy',
    '-an',
    output,
  ];

  /// An image scaled to exactly [width] × [height] with Lanczos, sharpened a
  /// little when [sharpen] (upscales), cropped first to [crop] (`w:h:x:y` in
  /// pixels), then turned [quarterTurns] clockwise and flipped. Saved as
  /// [format] (`jpg`, `png` or `webp`) at [quality].
  static List<String> editImage({
    required String input,
    required String output,
    required String format,
    int quality = 92,
    int? width,
    int? height,
    bool sharpen = false,
    String? crop,
    int quarterTurns = 0,
    bool flipHorizontal = false,
    bool flipVertical = false,
  }) {
    final filters = [
      if (crop != null) 'crop=$crop',
      if (width != null && height != null) 'scale=$width:$height:flags=lanczos',
      if (sharpen) 'unsharp=5:5:0.6:5:5:0.0',
      ...switch (quarterTurns % 4) {
        1 => ['transpose=1'],
        2 => ['transpose=1', 'transpose=1'],
        3 => ['transpose=2'],
        _ => const <String>[],
      },
      if (flipHorizontal) 'hflip',
      if (flipVertical) 'vflip',
    ];
    return [
      '-hide_banner',
      '-nostats',
      '-y',
      '-i',
      input,
      if (filters.isNotEmpty) ...['-vf', filters.join(',')],
      ...switch (format) {
        'png' => ['-c:v', 'png'],
        'webp' => ['-c:v', 'libwebp', '-quality', '$quality'],
        _ => ['-c:v', 'mjpeg', '-q:v', '${(2 + (100 - quality.clamp(0, 100)) * 29 / 100).round()}'],
      },
      '-frames:v',
      '1',
      '-update',
      '1',
      output,
    ];
  }

  // One palette for the whole clip: far fewer bands than ffmpeg's default GIF colours.
  static const _gifPalette = 'split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5';

  /// The video encoder arguments for [encoder] at good quality.
  static List<String> _videoEncoder(String encoder) => switch (encoder) {
    'hevc_videotoolbox' => ['-c:v', encoder, '-q:v', '65', '-tag:v', 'hvc1'],
    'hevc_mediacodec' => ['-c:v', encoder, '-b:v', '8M', '-tag:v', 'hvc1'],
    'h264_videotoolbox' => ['-c:v', encoder, '-q:v', '65'],
    _ => ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23'],
  };

  static List<String> _head(String input) => ['-hide_banner', '-nostats', '-progress', 'pipe:1', '-y', '-i', input];

  // Subtitles and cover art often can't go into the new container.
  static const _firstStreams = ['-map', '0:v:0', '-map', '0:a:0?'];

  static String _hevcBitrate(int? height) => switch (height ?? 2160) {
    >= 2000 => '20M',
    >= 1400 => '12M',
    _ => '8M',
  };
}

part of 'convert_options_notifier.dart';

final class const ConvertOptionsState({
  final ConvertOptions options = const ConvertOptions(),
  final LocalMediaInfo? source,
  final List<ConvertFormat> targets = const [],
  final ConvertFormat? compressFormat,
  super.status,
  super.message,
}) extends BaseState {
  static const _heights = [1080, 720, 480];

  /// Compress is offered for video and images, not audio.
  bool get canCompress => compressFormat != null;

  /// The output format for the current mode.
  ConvertFormat? get format => options.mode == .compress ? compressFormat : options.format;

  /// The request the Convert button starts, or null when nothing can run yet.
  ConvertRequest? get request {
    final (source, format) = (this.source, this.format);
    if (source == null || format == null) {
      return null;
    }
    return ConvertRequest(
      source: source,
      mode: options.mode,
      format: format,
      preset: options.preset,
      maxHeight: options.maxHeight,
      targetMb: options.targetMb,
      imageOptions: options.image,
      iphoneCompatible: options.iphoneCompatible,
    );
  }

  /// Max resolution choices below the video's own (never upscale).
  List<int> get heights => [
    for (final height in _heights)
      if (source?.shortSide case final side? when height < side) height,
  ];

  /// Longest-side choices below the image's own.
  List<int> get imageSides => [
    for (final side in const [4096, 2048, 1080])
      if (source?.longSide case final longest? when side < longest) side,
  ];

  /// The "aim for" slider's top: the file's own size.
  int get maxTargetMb => ((source?.sizeBytes ?? 0) / (1024 * 1024)).ceil().clamp(2, 1 << 20);

  ConvertOptionsState copyWith({ConvertOptions? options}) => ConvertOptionsState(
    options: options ?? this.options,
    source: source,
    targets: targets,
    compressFormat: compressFormat,
    status: status,
  );

  @override
  List<Object?> get props => [options, source, targets, compressFormat, ...super.props];
}

import 'package:get_it/get_it.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_downloader/domain/models/convert_format.dart';
import 'package:media_downloader/domain/models/convert_mode.dart';
import 'package:media_downloader/domain/models/convert_request.dart';
import 'package:media_downloader/domain/models/local_media_info.dart';
import 'package:media_downloader/domain/models/video_compress_preset.dart';
import 'package:media_downloader/domain/repositories/settings_repository.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:media_downloader/ui/features/convert/models/convert_options.dart';
import 'package:media_downloader/ui/features/convert/providers/convert_source/convert_source_notifier.dart';

part 'convert_options_state.dart';

/// The Convert / Compress choices for the picked file and the size estimate
/// (`state.request?.estimatedBytes`). Starts over for each new file.
/// See docs/features/convert.md#providers.
class ConvertOptionsNotifier extends BaseNotifier<ConvertOptionsState> {
  @override
  ConvertOptionsState build() {
    final (source, targets, compressFormat) = ref.watch(
      convertSourceProvider.select((state) => (state.source, state.targets, state.compressFormat)),
    );
    final settings = GetIt.I<SettingsRepository>().current;
    return ConvertOptionsState(
      source: source,
      targets: targets,
      compressFormat: compressFormat,
      options: ConvertOptions(
        mode: targets.isEmpty && compressFormat != null ? .compress : .convert,
        format: targets.firstOrNull,
        iphoneCompatible: settings.iphoneCompatible,
      ),
    );
  }

  void setMode(ConvertMode mode) => _set(state.options.copyWith(mode: mode));

  void setFormat(ConvertFormat format) => _set(state.options.copyWith(format: format));

  void setPreset(VideoCompressPreset preset) => _set(state.options.copyWith(preset: preset));

  /// Null keeps the original resolution.
  void setHeight(int? height) => _set(state.options.copyWith(maxHeight: () => height));

  /// Null turns "aim for a size" off.
  void setTargetMb(int? mb) => _set(state.options.copyWith(targetMb: () => mb?.clamp(1, state.maxTargetMb)));

  /// Turns "aim for a size" on at half the file's size, or off.
  void toggleTargetMb({required bool on}) => setTargetMb(on ? (state.maxTargetMb / 2).ceil() : null);

  /// Longest side in pixels, a percentage, or neither (original size).
  void setImageSize({int? longestSide, int? percent}) => _set(
    state.options.copyWith(
      image: state.options.image.copyWith(longestSide: () => longestSide, percent: () => percent),
    ),
  );

  void setImageQuality(int quality) =>
      _set(state.options.copyWith(image: state.options.image.copyWith(quality: quality.clamp(40, 100))));

  void setStripMetadata({required bool strip}) =>
      _set(state.options.copyWith(image: state.options.image.copyWith(stripMetadata: strip)));

  void setIphoneCompatible({required bool on}) => _set(state.options.copyWith(iphoneCompatible: on));

  void _set(ConvertOptions options) => state = state.copyWith(options: options);
}

final convertOptionsProvider = NotifierProvider(ConvertOptionsNotifier.new);

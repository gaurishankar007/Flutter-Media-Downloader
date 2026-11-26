import 'package:equatable/equatable.dart';

/// A direct progressive stream (video + audio, ≤ 720p) the preview can play
/// inline, with the headers the site requires. See docs/engine/media_engine.md#probe.
final class const PreviewStream({required final String url, final Map<String, String> headers = const {}})
    extends Equatable {
  @override
  List<Object?> get props => [url, headers];
}

part of 'convert_source_notifier.dart';

final class const ConvertSourceState({
  /// The picked file, once read.
  final LocalMediaInfo? source,

  /// What Convert can turn it into on this device.
  final List<ConvertFormat> targets = const [],

  /// What Compress writes; null when it can't be compressed (audio).
  final ConvertFormat? compressFormat,
  super.status,
  super.message,
}) extends BaseState {
  bool get isReading => status == .loading;

  ConvertSourceState copyWith({StateStatus? status, StateMessage? message}) => ConvertSourceState(
    source: source,
    targets: targets,
    compressFormat: compressFormat,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [source, targets, compressFormat, ...super.props];
}

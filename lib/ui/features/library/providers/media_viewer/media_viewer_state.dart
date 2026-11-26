part of 'media_viewer_notifier.dart';

final class const MediaViewerState({
  final List<String> ids = const [],
  final int index = 0,
  super.status,
  super.message,
}) extends BaseState {
  String? get currentId => index < ids.length ? ids[index] : null;

  MediaViewerState copyWith({List<String>? ids, int? index, StateStatus? status, StateMessage? message}) =>
      MediaViewerState(
        ids: ids ?? this.ids,
        index: index ?? this.index,
        status: status ?? this.status,
        message: message,
      );

  @override
  List<Object?> get props => [ids, index, ...super.props];
}

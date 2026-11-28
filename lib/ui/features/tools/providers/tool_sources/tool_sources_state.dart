part of 'tool_sources_notifier.dart';

final class const ToolSourcesState({
  /// The picked files, in the user's order.
  final List<LocalMediaInfo> sources = const [],

  /// Organize pages: a small JPG per page of the PDF, in order.
  final List<String> pageThumbnails = const [],
  final bool loadingPages = false,
  super.status,
  super.message,
}) extends BaseState {
  bool get isReading => status == .loading;

  LocalMediaInfo? get first => sources.firstOrNull;

  ToolSourcesState copyWith({
    List<LocalMediaInfo>? sources,
    List<String>? pageThumbnails,
    bool? loadingPages,
    StateStatus? status,
    StateMessage? message,
  }) => ToolSourcesState(
    sources: sources ?? this.sources,
    pageThumbnails: pageThumbnails ?? this.pageThumbnails,
    loadingPages: loadingPages ?? this.loadingPages,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [sources, pageThumbnails, loadingPages, ...super.props];
}

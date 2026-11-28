part of 'library_notifier.dart';

final class const LibraryState({
  /// Every item, newest first.
  final List<LibraryEntry> entries = const [],
  final LibraryFilter filter = const LibraryFilter(),
  final bool selecting = false,
  final Set<String> selectedIds = const {},
  super.status,
  super.message,
}) extends BaseState {
  /// [visibleItems] with each post's items folded into one card (the first
  /// item, carrying the group's ids). See docs/features/library.md#grid.
  List<LibraryEntry> get visible {
    final items = visibleItems;
    final groups = <String, List<LibraryEntry>>{};
    for (final entry in items) {
      if (entry.item.groupId case final groupId?) {
        groups.putIfAbsent(groupId, () => []).add(entry);
      }
    }
    final shown = <String>{};
    final cards = <LibraryEntry>[];
    for (final entry in items) {
      final groupId = entry.item.groupId;
      if (groupId == null) {
        cards.add(entry);
      } else if (shown.add(groupId)) {
        cards.add(_groupCard(groups[groupId]!));
      }
    }
    return cards;
  }

  static LibraryEntry _groupCard(List<LibraryEntry> members) {
    final ordered = [...members]..sort((a, b) => (a.item.groupIndex ?? 0).compareTo(b.item.groupIndex ?? 0));
    return ordered.first.withGroup([for (final member in ordered) member.id]);
  }

  /// [entries] narrowed and sorted by [filter], one per item.
  List<LibraryEntry> get visibleItems {
    final query = filter.query.trim().toLowerCase();
    final result = [
      for (final entry in entries)
        if (_matchesKind(entry.item) &&
            (filter.sites.isEmpty || filter.sites.contains(entry.item.site)) &&
            (query.isEmpty ||
                entry.item.title.toLowerCase().contains(query) ||
                (entry.item.uploader?.toLowerCase().contains(query) ?? false)))
          entry,
    ];
    switch (filter.sort) {
      case .newest:
        break;
      case .oldest:
        return result.reversed.toList();
      case .largest:
        result.sort((a, b) => b.item.sizeBytes.compareTo(a.item.sizeBytes));
    }
    return result;
  }

  /// Sites that have at least one item, in [Site] order.
  List<Site> get sites {
    final present = {for (final entry in entries) ?entry.item.site};
    return [
      for (final site in Site.values)
        if (present.contains(site)) site,
    ];
  }

  int get totalBytes => entries.fold(0, (sum, entry) => sum + entry.item.sizeBytes);

  List<LibraryEntry> get selected => [
    for (final entry in entries)
      if (selectedIds.contains(entry.id)) entry,
  ];

  LibraryEntry? byId(String id) => entries.where((entry) => entry.id == id).firstOrNull;

  /// Every item of the post [groupId], in the post's order (filters ignored).
  List<LibraryEntry> group(String groupId) => [
    for (final entry in entries)
      if (entry.item.groupId == groupId) entry,
  ]..sort((a, b) => (a.item.groupIndex ?? 0).compareTo(b.item.groupIndex ?? 0));

  bool _matchesKind(LibraryItem item) => switch (filter.kind) {
    .all => true,
    .videos => item.kind == .video,
    .audio => item.kind == .audio,
    .photos => item.kind == .photo,
    .documents => item.kind == .document,
  };

  LibraryState copyWith({
    List<LibraryEntry>? entries,
    LibraryFilter? filter,
    bool? selecting,
    Set<String>? selectedIds,
    StateStatus? status,
    StateMessage? message,
  }) => LibraryState(
    entries: entries ?? this.entries,
    filter: filter ?? this.filter,
    selecting: selecting ?? this.selecting,
    selectedIds: selectedIds ?? this.selectedIds,
    status: status ?? this.status,
    message: message,
  );

  @override
  List<Object?> get props => [entries, filter, selecting, selectedIds, ...super.props];
}

import 'package:equatable/equatable.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/features/library/models/library_kind_filter.dart';
import 'package:media_tool/ui/features/library/models/library_sort.dart';

/// What the Library grid shows: kind, sites (none = all), search text and sort.
final class const LibraryFilter({
  final LibraryKindFilter kind = .all,
  final Set<Site> sites = const {},
  final String query = '',
  final LibrarySort sort = .newest,
}) extends Equatable {
  bool get isNarrowed => kind != .all || sites.isNotEmpty || query.trim().isNotEmpty;

  LibraryFilter copyWith({LibraryKindFilter? kind, Set<Site>? sites, String? query, LibrarySort? sort}) =>
      LibraryFilter(
        kind: kind ?? this.kind,
        sites: sites ?? this.sites,
        query: query ?? this.query,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [kind, sites, query, sort];
}

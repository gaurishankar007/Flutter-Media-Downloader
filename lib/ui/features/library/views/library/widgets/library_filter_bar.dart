import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_tool/ui/features/library/models/library_kind_filter.dart';

/// All · Videos · Audio · Photos, then one chip per site that has items.
/// Scrolls sideways on narrow screens.
class const LibraryFilterBar({
  super.key,
  required final LibraryKindFilter selected,
  required final ValueChanged<LibraryKindFilter> onSelected,
  final List<Site> sites = const [],
  final Set<Site> selectedSites = const {},
  final ValueChanged<Site>? onSiteToggled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      clipBehavior: .none,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          for (final filter in LibraryKindFilter.values)
            SelectChip(
              label: filter.label,
              icon: filter.icon,
              selected: filter == selected,
              onSelected: () => onSelected(filter),
            ),
          if (sites.length > 1)
            for (final site in sites)
              SelectChip(
                label: site.label,
                selected: selectedSites.contains(site),
                onSelected: () => onSiteToggled?.call(site),
              ),
        ],
      ),
    );
  }
}

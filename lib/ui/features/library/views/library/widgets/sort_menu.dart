import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_tool/ui/features/library/models/library_sort.dart';

/// Newest / Oldest / Largest.
class const SortMenu({
  super.key,
  required final LibrarySort selected,
  required final ValueChanged<LibrarySort> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final sort in LibrarySort.values)
          MenuItemButton(
            onPressed: () => onSelected(sort),
            leadingIcon: Icon(sort == selected ? Symbols.check_rounded : null, size: 18, color: context.colors.primary),
            child: Text(sort.label, style: context.text.body),
          ),
      ],
      builder: (context, controller, _) => AppIconButton(
        icon: Symbols.sort_rounded,
        label: LibraryMessages.sort,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

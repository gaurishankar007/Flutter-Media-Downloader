import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/ui/base/chips/chip_row.dart';
import 'package:media_tool/ui/core/ui/base/chips/select_chip.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';

/// A titled row of chips picking one of [choices].
class const ChoiceSection<T>({
  super.key,
  required final String title,
  required final List<({T value, String label})> choices,
  required final T selected,
  required final ValueChanged<T> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: title),
        ChipRow(
          wrap: true,
          children: [
            for (final choice in choices)
              SelectChip(
                label: choice.label,
                selected: choice.value == selected,
                onSelected: () => onSelected(choice.value),
              ),
          ],
        ),
      ],
    );
  }
}

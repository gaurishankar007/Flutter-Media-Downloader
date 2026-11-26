import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/utils/format_utils.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';

/// A small label over a file size ("Before / 120 MB").
class const SizeColumn({super.key, required final String label, required final int bytes}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        Text(label, style: context.text.caption.copyWith(color: context.colors.textSecondary)),
        Text(FormatUtils.bytes(bytes), style: context.text.numeric),
      ],
    );
  }
}

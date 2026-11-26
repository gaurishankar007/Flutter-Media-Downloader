import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/utils/format_utils.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// "42 items · 3.1 GB".
class const StorageSummary({super.key, required final int count, required final int bytes}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      LibraryMessages.summary(count, FormatUtils.bytes(bytes)),
      style: context.text.label.copyWith(color: context.colors.textSecondary),
    );
  }
}

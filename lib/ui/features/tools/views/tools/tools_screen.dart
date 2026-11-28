import 'package:auto_route/auto_route.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/ui/base/cards/source_tile.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/features/tools/models/tool_category.dart';
import 'package:media_tool/ui/features/tools/views/tools/widgets/tool_section.dart';

/// The Tools tab: Convert & compress, then the PDF, GIF & video and image
/// tools. Each opens its own screen. See docs/features/tools.md.
@RoutePage()
class const ToolsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenScrollView(
      children: [
        const ScreenHeader(title: ToolsMessages.title, subtitle: ToolsMessages.subtitle),
        SourceTile(
          icon: Symbols.swap_horiz_rounded,
          title: ToolsMessages.convertTitle,
          subtitle: ToolsMessages.convertBody,
          onTap: () => context.router.push(const ConvertRoute()),
        ),
        for (final category in ToolCategory.values) ToolSection(category: category),
      ],
    );
  }
}

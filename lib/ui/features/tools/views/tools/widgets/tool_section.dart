import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/routing/routes.gr.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/cards/source_tile.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/models/tool.dart';
import 'package:media_tool/ui/features/tools/models/tool_category.dart';

/// One hub section: its title and its tools' cards, in as many columns as fit.
class const ToolSection({super.key, required final ToolCategory category}) extends StatelessWidget {
  static const _minCardWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    final tools = [
      for (final tool in Tool.values)
        if (tool.category == category) tool,
    ];
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: category.label),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / _minCardWidth).floor().clamp(1, 3);
            final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final tool in tools)
                  SizedBox(
                    width: width,
                    child: SourceTile(
                      icon: tool.icon,
                      title: tool.title,
                      subtitle: tool.body,
                      onTap: () => context.router.push(ToolRoute(tool: tool)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

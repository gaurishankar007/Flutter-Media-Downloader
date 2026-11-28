import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/ui/base/buttons/ghost_button.dart';
import 'package:media_tool/ui/core/ui/base/progress/gradient_progress_bar.dart';
import 'package:media_tool/ui/core/ui/base/text/section_header.dart';
import 'package:media_tool/ui/features/tools/providers/tool_options/tool_options_notifier.dart';
import 'package:media_tool/ui/features/tools/providers/tool_sources/tool_sources_notifier.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/option_note.dart';
import 'package:media_tool/ui/features/tools/views/tool/widgets/page_tile.dart';

/// Organize pages: every page as a thumbnail. Drag one onto another to move
/// it there; each has Rotate and Delete.
class const OrganizePagesOptions({super.key}) extends ConsumerWidget {
  static const _minTileWidth = 132.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = toolOptionsProvider(.organizePdf);
    final pages = ref.watch(provider.select((state) => state.pages));
    final notifier = ref.read(provider.notifier);
    final sources = ref.watch(toolSourcesProvider(.organizePdf));
    final thumbnails = sources.pageThumbnails;
    final total = sources.first?.pageCount ?? 0;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(
          title: total == pages.length ? ToolsMessages.pages : '${ToolsMessages.pages} · ${pages.length} / $total',
          trailing: GhostButton(label: ToolsMessages.resetPages, onPressed: notifier.resetPages),
        ),
        const OptionNote(text: ToolsMessages.pagesHint),
        const SizedBox(height: AppSpacing.md),
        if (sources.loadingPages) ...[
          const GradientProgressBar(),
          const OptionNote(text: ToolsMessages.loadingPages),
        ] else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / _minTileWidth).floor().clamp(2, 8);
              final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (index, page) in pages.indexed)
                    SizedBox(
                      key: ValueKey('${page.index}-$index'),
                      width: width,
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (details) => details.data != index,
                        // Dropped on a later page: it goes after it; on an earlier one: before it.
                        onAcceptWithDetails: (details) =>
                            notifier.reorderPages(details.data, details.data < index ? index + 1 : index),
                        builder: (context, candidates, _) {
                          final tile = PageTile(
                            number: page.index + 1,
                            quarterTurns: page.quarterTurns,
                            thumbnail: page.index < thumbnails.length ? thumbnails[page.index] : null,
                            highlighted: candidates.isNotEmpty,
                            onRotate: () => notifier.rotatePage(index),
                            onDelete: () => notifier.deletePage(index),
                          );
                          return LongPressDraggable<int>(
                            data: index,
                            feedback: SizedBox(
                              width: width,
                              child: Opacity(opacity: 0.85, child: tile),
                            ),
                            childWhenDragging: Opacity(opacity: 0.3, child: tile),
                            child: tile,
                          );
                        },
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

import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/cards/app_card.dart';
import 'package:media_tool/ui/features/convert/views/convert/widgets/format_row.dart';

/// The formats the converter handles, and what "make smaller" does.
class const FormatOverviewCard({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.lg,
        children: [
          const FormatRow(
            icon: Symbols.movie_rounded,
            title: ConvertMessages.videoFormats,
            formats: ['MP4', 'MOV', 'MKV', 'WebM'],
          ),
          const FormatRow(
            icon: Symbols.music_note_rounded,
            title: ConvertMessages.audioFormats,
            formats: ['MP3', 'M4A'],
          ),
          const FormatRow(
            icon: Symbols.image_rounded,
            title: ConvertMessages.imageFormats,
            formats: ['JPG', 'PNG', 'WebP', 'HEIC'],
          ),
          const Divider(),
          Row(
            crossAxisAlignment: .start,
            spacing: AppSpacing.md,
            children: [
              Icon(Symbols.compress_rounded, color: context.colors.primaryText),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text(ConvertMessages.shrink, style: context.text.bodyStrong),
                    Text(
                      ConvertMessages.shrinkBody,
                      style: context.text.label.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

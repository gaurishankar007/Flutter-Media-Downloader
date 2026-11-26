import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/media_info.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/core/ui/base/media/site_badge.dart';
import 'package:media_tool/ui/features/download/views/preview/widgets/preview_media.dart';

/// Thumbnail (playable when possible), title, uploader and site.
class const PreviewHeader({super.key, required final MediaInfo info}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.md,
      children: [
        PreviewMedia(info: info),
        Text(info.title, maxLines: 2, overflow: .ellipsis, style: context.text.headline),
        Row(
          spacing: AppSpacing.sm,
          children: [
            SiteBadge(site: info.site, size: 18),
            Expanded(
              child: Text(
                [?info.uploader, info.site.label].join(' · '),
                maxLines: 1,
                overflow: .ellipsis,
                style: context.text.label.copyWith(color: context.colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

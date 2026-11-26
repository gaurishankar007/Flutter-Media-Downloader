import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/media/site_badge.dart';

/// Badge + name for every supported site.
class const SupportedSitesRow({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = context.text.label.copyWith(color: context.colors.textSecondary);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final site in Site.values)
          Row(
            mainAxisSize: .min,
            spacing: AppSpacing.xs + 2,
            children: [
              SiteBadge(site: site, size: 18),
              Text(site.label, style: style),
            ],
          ),
      ],
    );
  }
}

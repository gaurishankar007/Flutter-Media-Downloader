import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/domain/models/site_cookies.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/app_icon_button.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/media/site_badge.dart';

/// One site: its cookie status, Import / Replace, and Remove.
class const SiteCookiesRow({
  super.key,
  required final Site site,
  required final SiteCookies? cookies,
  required final bool busy,
  required final VoidCallback? onImport,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imported = cookies;
    final info = Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        Text(site.label, maxLines: 1, overflow: .ellipsis, style: context.text.bodyStrong),
        Text(
          imported == null
              ? CookiesMessages.notSet
              : CookiesMessages.imported(imported.count, DateFormat.yMMMd().format(imported.importedAt)),
          maxLines: 2,
          overflow: .ellipsis,
          style: context.text.label.copyWith(color: imported == null ? colors.textMuted : colors.success),
        ),
      ],
    );
    final buttons = [
      if (busy)
        const SizedBox.square(
          dimension: 44,
          child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        )
      else
        TonalButton(
          label: imported == null ? CookiesMessages.import : CookiesMessages.replace,
          icon: Symbols.upload_file_rounded,
          onPressed: onImport,
        ),
      if (imported != null)
        AppIconButton(
          icon: Symbols.delete_rounded,
          label: CommonMessages.remove,
          destructive: true,
          onPressed: onRemove,
        ),
    ];

    return Padding(
      padding: const .symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: LayoutBuilder(
        // Narrow phones: the buttons go under the status so it stays readable.
        builder: (context, constraints) => constraints.maxWidth < 340
            ? Column(
                crossAxisAlignment: .stretch,
                spacing: AppSpacing.sm,
                children: [
                  Row(
                    spacing: AppSpacing.md,
                    children: [
                      SiteBadge(site: site, size: 32),
                      Expanded(child: info),
                    ],
                  ),
                  Row(mainAxisAlignment: .end, spacing: AppSpacing.sm, children: buttons),
                ],
              )
            : Row(
                spacing: AppSpacing.md,
                children: [
                  SiteBadge(site: site, size: 32),
                  Expanded(child: info),
                  ...buttons,
                ],
              ),
      ),
    );
  }
}

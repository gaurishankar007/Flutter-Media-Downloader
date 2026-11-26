import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/site.dart';
import 'package:media_downloader/ui/core/themes/app_motion.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/gradient_button.dart';
import 'package:media_downloader/ui/core/ui/base/media/site_badge.dart';

/// The big link input: site badge once recognised, Paste when empty, Clear otherwise.
class const LinkField({
  super.key,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final VoidCallback onPaste,
  required final VoidCallback onClear,
  final Site? site,
  final ValueChanged<String>? onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 64,
      padding: const .only(left: AppSpacing.lg, right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.lgAll,
        border: .all(color: site == null ? colors.outline : colors.primary.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.normal,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: site == null
                ? Icon(Symbols.link_rounded, key: const ValueKey('link'), color: colors.textMuted)
                : SiteBadge(key: ValueKey(site), site: site!, size: 24),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              keyboardType: .url,
              textInputAction: .go,
              autocorrect: false,
              style: context.text.body,
              decoration: InputDecoration(
                hintText: DownloadMessages.linkHint,
                hintStyle: context.text.body.copyWith(color: colors.textMuted),
                border: .none,
                isCollapsed: true,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? GradientButton(
                    label: DownloadMessages.paste,
                    icon: Symbols.content_paste_rounded,
                    compact: true,
                    onPressed: onPaste,
                  )
                : IconButton(
                    tooltip: DownloadMessages.clearLink,
                    onPressed: onClear,
                    icon: Icon(Symbols.close_rounded, color: colors.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }
}

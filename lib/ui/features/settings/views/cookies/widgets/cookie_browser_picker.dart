import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/domain/models/cookie_browser.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/ui/base/chips/select_chip.dart';

/// macOS: Off / Safari / Chrome / Firefox.
class const CookieBrowserPicker({
  super.key,
  required final CookieBrowser selected,
  required final ValueChanged<CookieBrowser> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final browser in CookieBrowser.values)
          SelectChip(
            label: switch (browser) {
              .none => CookiesMessages.browserNone,
              .safari => CookiesMessages.browserSafari,
              .chrome => CookiesMessages.browserChrome,
              .firefox => CookiesMessages.browserFirefox,
            },
            selected: browser == selected,
            onSelected: () => onSelected(browser),
          ),
      ],
    );
  }
}

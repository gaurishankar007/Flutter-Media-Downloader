import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/cards/app_card.dart';

/// Plain steps for exporting cookies.txt, and where the cookies stay.
class const CookiesHowToCard({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = [CookiesMessages.step1, CookiesMessages.step2, CookiesMessages.step3, CookiesMessages.step4];
    return AppCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.md,
        children: [
          for (final (index, step) in steps.indexed)
            Row(
              crossAxisAlignment: .start,
              spacing: AppSpacing.md,
              children: [
                Text('${index + 1}.', style: context.text.bodyStrong.copyWith(color: colors.primaryText)),
                Expanded(child: Text(step, style: context.text.body)),
              ],
            ),
          Text(CookiesMessages.privacy, style: context.text.label.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

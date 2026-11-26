import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_downloader/core/messages/app_messages.dart';
import 'package:media_downloader/ui/core/providers/base/base_notifier.dart';
import 'package:media_downloader/ui/core/themes/app_spacing.dart';
import 'package:media_downloader/ui/core/themes/theme.dart';
import 'package:media_downloader/ui/core/ui/base/buttons/tonal_button.dart';
import 'package:media_downloader/ui/core/ui/base/text/section_header.dart';
import 'package:media_downloader/ui/core/utils/toast_util.dart';

/// Every toast the app can show, fired through [ToastUtil.showStateMessage]:
/// the same call `listenMessages` makes when a notifier sets a message.
class const GalleryToastsSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void show(StateMessage message) => ToastUtil.showStateMessage(context, message);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader(title: DesignGalleryMessages.toasts),
        Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              DesignGalleryMessages.toastsBody,
              style: context.text.label.copyWith(color: context.colors.textSecondary),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TonalButton(
                  label: DesignGalleryMessages.toastSuccess,
                  icon: Symbols.check_circle_rounded,
                  onPressed: () => show(const SuccessMessage(DesignGalleryMessages.sampleSuccess)),
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastError,
                  icon: Symbols.error_rounded,
                  onPressed: () => show(const ErrorMessage(DesignGalleryMessages.sampleError)),
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastWarning,
                  icon: Symbols.warning_rounded,
                  onPressed: () => show(const WarningMessage(DesignGalleryMessages.sampleWarning)),
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastInfo,
                  icon: Symbols.info_rounded,
                  onPressed: () => show(const NormalMessage(DesignGalleryMessages.sampleInfo)),
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastLong,
                  icon: Symbols.notes_rounded,
                  onPressed: () => show(const ErrorMessage(DesignGalleryMessages.sampleLongToast)),
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastStack,
                  icon: Symbols.stacks_rounded,
                  onPressed: () {
                    show(const SuccessMessage(DesignGalleryMessages.sampleSuccess));
                    show(const WarningMessage(DesignGalleryMessages.sampleWarning));
                    show(const NormalMessage(DesignGalleryMessages.sampleInfo));
                  },
                ),
                TonalButton(
                  label: DesignGalleryMessages.toastRepeat,
                  icon: Symbols.repeat_rounded,
                  onPressed: () {
                    // The second, identical toast is skipped while the first is up.
                    show(const NormalMessage(DesignGalleryMessages.sampleRepeat));
                    show(const NormalMessage(DesignGalleryMessages.sampleRepeat));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

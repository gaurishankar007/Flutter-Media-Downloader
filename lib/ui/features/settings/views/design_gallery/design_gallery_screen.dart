import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_back_button.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_header.dart';
import 'package:media_tool/ui/core/ui/base/layout/screen_scroll_view.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_controls_section.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_jobs_section.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_library_section.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_overlays_section.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_states_section.dart';
import 'package:media_tool/ui/features/settings/views/design_gallery/widgets/gallery_toasts_section.dart';

/// Debug builds only: every base component on one page.
@RoutePage()
class const DesignGalleryScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenScrollView(
        children: [
          ScreenBackButton(),
          ScreenHeader(title: DesignGalleryMessages.title, subtitle: DesignGalleryMessages.subtitle),
          GalleryControlsSection(),
          GalleryJobsSection(),
          GalleryLibrarySection(),
          GalleryOverlaysSection(),
          GalleryStatesSection(),
          GalleryToastsSection(),
        ],
      ),
    );
  }
}

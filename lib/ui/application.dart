import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_tool/domain/models/app_theme_mode.dart';
import 'package:media_tool/routing/routes.dart';
import 'package:media_tool/ui/core/providers/screen_type/screen_type_notifier.dart';
import 'package:media_tool/ui/core/themes/theme_data.dart';
import 'package:media_tool/ui/features/settings/providers/settings/settings_notifier.dart';

/// Root widget: router, themes and breakpoint tracking.
class const MediaToolApp({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<MediaToolApp> createState() => _MediaToolAppState();
}

class _MediaToolAppState extends ConsumerState<MediaToolApp> with WidgetsBindingObserver {
  final _router = AppRouter();
  final _lightTheme = buildTheme(.light);
  final _darkTheme = buildTheme(.dark);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Riverpod rejects state changes mid-build, so update after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(screenTypeProvider.notifier).update();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((state) => state.settings.themeMode));
    return MaterialApp.router(
      title: 'Media Tool',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
      },
      routerConfig: _router.config(),
    );
  }
}

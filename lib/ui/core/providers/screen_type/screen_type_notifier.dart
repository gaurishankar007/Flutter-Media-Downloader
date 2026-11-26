import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_tool/ui/core/providers/base/base_notifier.dart';
import 'package:media_tool/ui/core/providers/screen_type/screen_type.dart';

/// The current breakpoint. Only changes when the window crosses one, so
/// widgets watching it don't rebuild on every resize.
class ScreenTypeNotifier extends BaseNotifier<ScreenType> {
  @override
  ScreenType build() => .fromWidth(_logicalWidth);

  /// Called after a metrics change (window resize, rotation).
  void update() {
    final next = ScreenType.fromWidth(_logicalWidth);
    if (ref.mounted && next != state) {
      state = next;
    }
  }

  static double get _logicalWidth {
    final view = PlatformDispatcher.instance.implicitView ?? PlatformDispatcher.instance.views.first;
    return view.physicalSize.width / view.devicePixelRatio;
  }
}

final screenTypeProvider = NotifierProvider(ScreenTypeNotifier.new);

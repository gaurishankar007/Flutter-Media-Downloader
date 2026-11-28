import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:media_tool/ui/core/utils/local_media.dart';
import 'package:video_player/video_player.dart';

/// A player for the video at [path], made again when it changes and
/// disposed with the widget. `failed` when it can't play here (Linux has no
/// player); `ready` once it can.
({VideoPlayerController? controller, bool ready, bool failed}) usePreviewPlayer(String? path) {
  final controller = useMemoized(() => path == null ? null : LocalMedia.player(path), [path]);
  final init = useFuture(useMemoized(() => controller?.initialize(), [controller]));
  useEffect(() => controller?.dispose, [controller]);
  final done = init.connectionState == .done;
  final ready = done && !init.hasError && (controller?.value.isInitialized ?? false);
  return (controller: controller, ready: ready, failed: init.hasError || (done && !ready));
}

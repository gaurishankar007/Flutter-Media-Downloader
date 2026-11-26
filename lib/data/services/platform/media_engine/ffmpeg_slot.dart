import 'dart:async';

import 'package:injectable/injectable.dart';

/// The one ffmpeg slot: conversions (and re-encodes) run one at a time, since
/// they're CPU and battery heavy. See docs/engine/media_engine.md#concurrency.
@lazySingleton
final class FfmpegSlot {
  Future<void> _tail = Future.value();

  /// Waits for the slot. Call the returned function once done to free it.
  Future<void Function()> acquire() async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    return () {
      if (!done.isCompleted) {
        done.complete();
      }
    };
  }
}

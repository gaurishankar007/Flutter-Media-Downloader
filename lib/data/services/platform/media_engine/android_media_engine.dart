import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/clients/platform/media_engine_api.g.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/probe_response_dto.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/domain/models/engine_info.dart';

/// The Pigeon engine bridge. Android: youtubedl-android (Kotlin:
/// `engine/MediaEngine.kt`). iOS: embedded CPython + FFmpegKit (Swift:
/// `Engine/IosMediaEngine.swift`), same API and the same stdout lines.
/// See docs/engine/android_engine.md and docs/engine/ios_engine.md.
@LazySingleton(as: MediaEngine, env: [PlatformEnv.android, PlatformEnv.ios])
final class AndroidMediaEngine({required final ErrorHandler _errorHandler}) implements MediaEngine {
  final _api = MediaEngineHostApi();

  // One native event channel for every job, filtered per job below.
  late final Stream<EngineEventMsg> _events = engineEvents();

  @override
  FutureData<EngineInfo> init() => _errorHandler.execute(action: 'engine.init', () async {
    final info = await _api.init();
    return SuccessState(
      data: EngineInfo(ytDlpVersion: info.ytDlpVersion, encoders: info.encoders),
    );
  });

  @override
  FutureData<ProbeResponseDto> probe(List<String> args) => _errorHandler.execute(action: 'engine.probe', () async {
    final output = await _api.probe(args);
    final dto = ProbeResponseDto.fromJson(jsonDecode(output) as JsonMap);
    return SuccessState(data: dto);
  });

  @override
  Stream<EngineEvent> download(String jobId, List<String> args) => _run(jobId, () => _api.startDownload(jobId, args));

  @override
  Stream<EngineEvent> ffmpeg(String jobId, List<String> args) => _run(jobId, () => _api.startFfmpeg(jobId, args));

  @override
  Future<void> cancel(String jobId) => _errorHandler.executeSafe(() async {
    await _api.cancel(jobId);
  });

  @override
  FutureData<String> updateYtDlp() => _errorHandler.execute(action: 'engine.update', () async {
    return SuccessState(data: await _api.updateYtDlp());
  });

  Stream<EngineEvent> _run(String jobId, Future<void> Function() start) {
    late final StreamController<EngineEvent> controller;
    StreamSubscription<EngineEventMsg>? subscription;
    controller = StreamController(
      onListen: () async {
        // Listen before starting so the first lines aren't missed.
        subscription = _events.where((event) => event.jobId == jobId).listen((event) {
          controller.add(switch (event.kind) {
            .line => EngineLine(event.payload),
            .done => const EngineDone(),
            .error => EngineFailed(event.payload),
            .cancelled => const EngineCancelled(),
          });
          if (event.kind != .line) {
            unawaited(subscription?.cancel());
            unawaited(controller.close());
          }
        });
        try {
          await start();
        } catch (error) {
          await subscription?.cancel();
          controller.add(EngineFailed('$error'));
          await controller.close();
        }
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}

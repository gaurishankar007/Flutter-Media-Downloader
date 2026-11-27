import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/config/injector/platform_env.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/engine_errors.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/responses/probe_response_dto.dart';
import 'package:media_tool/data/services/platform/media_engine/desktop_engine_binaries.dart';
import 'package:media_tool/data/services/platform/media_engine/engine_event.dart';
import 'package:media_tool/data/services/platform/media_engine/media_engine.dart';
import 'package:media_tool/domain/models/engine_info.dart';

/// Runs the bundled yt-dlp / ffmpeg binaries with `dart:io` processes on
/// macOS, Windows and Linux (the macOS app isn't sandboxed). yt-dlp runs from
/// a copy in the app's folder so `-U` can update it.
/// See docs/engine/desktop_engine.md.
@LazySingleton(as: MediaEngine, env: PlatformEnv.desktop)
final class DesktopMediaEngine({
  required final ErrorHandler _errorHandler,
  required final DesktopEngineBinaries _binaries,
}) implements MediaEngine {
  static const _maxErrorChars = 4000;

  final _running = <String, Process>{};
  final _cancelled = <String>{};
  Future<String>? _ready;

  String get _ffmpeg => _binaries.ffmpeg;

  String get _bundledYtDlp => _binaries.bundledYtDlp;

  Map<String, String> get _environment => _binaries.environment;

  /// Machine-specific options the shared builders can't know.
  List<String> get _ytDlpPrefix => [
    '--ffmpeg-location',
    _binaries.bin,
    if (_binaries.deno case final deno?) ...['--js-runtimes', 'deno:$deno'],
  ];

  @override
  FutureData<EngineInfo> init() => _errorHandler.execute(action: 'engine.init', () async {
    if (!File(_bundledYtDlp).existsSync() || !File(_ffmpeg).existsSync()) {
      return FailureState(message: EngineMessages.initFailed, error: 'Engine binaries missing in ${_binaries.bin}');
    }
    final ytDlp = await _ytDlp();
    final (version, encoders) = await (_version(ytDlp), _encoders()).wait;
    return SuccessState(
      data: EngineInfo(ytDlpVersion: version ?? '', encoders: encoders),
    );
  });

  @override
  FutureData<ProbeResponseDto> probe(List<String> args) => _errorHandler.execute(action: 'engine.probe', () async {
    final result = await Process.run(
      await _ytDlp(),
      [..._ytDlpPrefix, ...args],
      environment: _environment,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw EngineException(result.stderr as String);
    }
    final dto = ProbeResponseDto.fromJson(jsonDecode(result.stdout as String) as JsonMap);
    return SuccessState(data: dto);
  });

  @override
  Stream<EngineEvent> download(String jobId, List<String> args) =>
      _run(jobId, () async => (await _ytDlp(), [..._ytDlpPrefix, ...args]));

  @override
  Stream<EngineEvent> ffmpeg(String jobId, List<String> args) => _run(jobId, () async => (_ffmpeg, args));

  @override
  Future<void> cancel(String jobId) => _errorHandler.executeSafe(() async {
    final process = _running[jobId];
    if (process == null) {
      return;
    }
    _cancelled.add(jobId);
    await _binaries.killTree(process);
  });

  @override
  FutureData<String> updateYtDlp() => _errorHandler.execute(action: 'engine.update', () async {
    _ready = null;
    final ytDlp = await _ytDlp();
    if (ytDlp == _bundledYtDlp) {
      throw const EngineException('No writable yt-dlp copy to update');
    }
    final result = await Process.run(
      ytDlp,
      ['-U'],
      environment: _environment,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw EngineException('${result.stderr}\n${result.stdout}');
    }
    final version = await _version(ytDlp);
    if (version == null) {
      _ready = null;
      throw EngineException('yt-dlp broken after update: ${result.stdout}');
    }
    return SuccessState(data: version);
  });

  /// The yt-dlp to run: the Application Support copy, made from the bundled
  /// binary when missing or broken; the bundled one if the copy can't work.
  Future<String> _ytDlp() => _ready ??= _prepareYtDlp();

  Future<String> _prepareYtDlp() async {
    final copy = File(_binaries.ytDlpCopy);
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!copy.existsSync() || attempt > 0) {
        try {
          await copy.parent.create(recursive: true);
          await File(_bundledYtDlp).copy(copy.path);
          await _binaries.makeExecutable(copy.path);
        } on Exception {
          break;
        }
      }
      if (await _version(copy.path) != null) {
        return copy.path;
      }
    }
    return _bundledYtDlp;
  }

  Future<String?> _version(String ytDlp) async {
    try {
      final result = await Process.run(ytDlp, ['--version'], environment: _environment);
      final version = (result.stdout as String).trim();
      return result.exitCode == 0 && version.isNotEmpty ? version : null;
    } on ProcessException {
      return null;
    }
  }

  /// Video encoder names from `ffmpeg -encoders` (lines like ` V....D libx264  H.264 ...`).
  Future<List<String>> _encoders() async {
    try {
      final result = await Process.run(_ffmpeg, ['-hide_banner', '-encoders'], environment: _environment);
      return [
        for (final line in const LineSplitter().convert(result.stdout as String).map((line) => line.trim()))
          if (line.length > 7 && line[0] == 'V' && line[6] == ' ') line.substring(7).trim().split(' ').first,
      ];
    } on ProcessException {
      return const [];
    }
  }

  Stream<EngineEvent> _run(String jobId, Future<(String, List<String>)> Function() command) {
    final controller = StreamController<EngineEvent>();
    controller.onListen = () async {
      try {
        final (executable, args) = await command();
        final process = await Process.start(executable, args, environment: _environment);
        _running[jobId] = process;
        final stderr = StringBuffer();
        final outDone = process.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .forEach((line) => controller.add(EngineLine(line)));
        final errDone = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).forEach(stderr.write);
        final exitCode = await process.exitCode;
        await (outDone, errDone).wait;
        _running.remove(jobId);
        final output = stderr.toString();
        controller.add(switch (exitCode) {
          _ when _cancelled.remove(jobId) => const EngineCancelled(),
          0 => const EngineDone(),
          _ => EngineFailed(output.length > _maxErrorChars ? output.substring(output.length - _maxErrorChars) : output),
        });
      } catch (error) {
        _running.remove(jobId);
        controller.add(_cancelled.remove(jobId) ? const EngineCancelled() : EngineFailed('$error'));
      } finally {
        await controller.close();
      }
    };
    return controller.stream;
  }
}

import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/messages/app_messages.dart';
import 'package:media_tool/core/services/app_directories.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/mappers/system_sample_mapper.dart';
import 'package:media_tool/data/services/local/app_files_local_service.dart';
import 'package:media_tool/data/services/platform/speed_test/speed_test_service.dart';
import 'package:media_tool/data/services/platform/system_monitor/system_monitor_service.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_hardware.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/speed_test.dart';
import 'package:media_tool/domain/models/speed_test_result.dart';
import 'package:media_tool/domain/models/system_profile.dart';
import 'package:media_tool/domain/models/system_sample.dart';
import 'package:media_tool/domain/repositories/system_monitor_repository.dart';
import 'package:path/path.dart' as p;

@LazySingleton(as: SystemMonitorRepository)
final class SystemMonitorRepositoryImpl({
  required final SystemMonitorService _service,
  required final SpeedTestService _speedTests,
  required final AppFilesLocalService _appFiles,
  required final AppDirectories _directories,
  required final ErrorHandler _errorHandler,
}) implements SystemMonitorRepository {
  static const _mb = 1024 * 1024;

  static final _desktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Big enough to outgrow CPU caches and drive buffers, small enough for a phone.
  static final _memoryTestBytes = (_desktop ? 256 : 128) * _mb;
  static final _storageTestBytes = (_desktop ? 1024 : 512) * _mb;

  SystemProfile? _profile;
  SystemSampleMsg? _previous;
  int? _appBytes;
  final _speedResults = <SpeedTest, SpeedTestResult>{};

  @override
  SystemProfile? get knownProfile => _profile;

  @override
  FutureData<SystemProfile> profile() => _errorHandler.execute(action: 'systemMonitor.profile', () async {
    if (_profile case final profile?) {
      return SuccessState(data: profile);
    }
    final capabilities = await _service.capabilities();
    // Hardware facts are extras: if they fail, the live cards still show.
    final hardware = switch (await _hardware()) {
      SuccessState(:final data) => data,
      _ => null,
    };
    return SuccessState(data: _profile = SystemSampleMapper.profile(capabilities, hardware));
  });

  FutureData<DeviceHardware> _hardware() => _errorHandler.execute(action: 'systemMonitor.hardware', () async {
    return SuccessState(data: SystemSampleMapper.hardware(await _service.hardware()));
  });

  @override
  FutureData<SystemSample> sample() => _errorHandler.execute(action: 'systemMonitor.sample', () async {
    final current = await _service.sample();
    final sample = SystemSampleMapper.fromMsg(current, _previous);
    _previous = current;
    return SuccessState(data: sample);
  });

  @override
  FutureData<DeviceStorage?> storage({bool measureAppFiles = false}) =>
      _errorHandler.execute(action: 'systemMonitor.storage', () async {
        final storage = SystemSampleMapper.storage(await _service.storage());
        if (measureAppFiles || _appBytes == null) {
          _appBytes = await _appFiles.sizeInBytes();
        }
        return SuccessState(data: storage?.withAppBytes(_appBytes));
      });

  @override
  FutureData<BatteryStatus?> battery() => _errorHandler.execute(action: 'systemMonitor.battery', () async {
    return SuccessState(data: SystemSampleMapper.battery(await _service.battery()));
  });

  @override
  SpeedTestResult? lastSpeedTest(SpeedTest test) => _speedResults[test];

  @override
  FutureData<SpeedTestResult> runSpeedTest(SpeedTest test) =>
      _errorHandler.execute(action: 'systemMonitor.speedTest.${test.name}', () async {
        final RawSpeed raw;
        switch (test) {
          case .memory:
            raw = await _speedTests.memory(_memoryTestBytes);
          case .storage:
            final free = (await _service.storage()).freeBytes;
            if (free != null && free < _storageTestBytes * 2) {
              return const FailureState(message: CommonMessages.noSpace);
            }
            raw = await _speedTests.storage(p.join(_directories.work, 'speed_test.tmp'), _storageTestBytes);
        }
        final result = SpeedTestResult(
          readBytesPerSecond: raw.read,
          writeBytesPerSecond: raw.write,
          copyBytesPerSecond: raw.copy,
        );
        _speedResults[test] = result;
        return SuccessState(data: result);
      });
}

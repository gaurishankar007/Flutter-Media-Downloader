import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/platform/system_monitor_api.g.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/models/mappers/system_sample_mapper.dart';
import 'package:media_tool/data/services/local/app_files_local_service.dart';
import 'package:media_tool/data/services/platform/system_monitor/system_monitor_service.dart';
import 'package:media_tool/domain/models/battery_status.dart';
import 'package:media_tool/domain/models/device_storage.dart';
import 'package:media_tool/domain/models/system_metric.dart';
import 'package:media_tool/domain/models/system_sample.dart';
import 'package:media_tool/domain/repositories/system_monitor_repository.dart';

@LazySingleton(as: SystemMonitorRepository)
final class SystemMonitorRepositoryImpl({
  required final SystemMonitorService _service,
  required final AppFilesLocalService _appFiles,
  required final ErrorHandler _errorHandler,
}) implements SystemMonitorRepository {
  List<SystemMetric>? _metrics;
  SystemSampleMsg? _previous;
  int? _appBytes;

  @override
  List<SystemMetric>? get knownMetrics => _metrics;

  @override
  FutureList<SystemMetric> metrics() => _errorHandler.execute(action: 'systemMonitor.metrics', () async {
    return SuccessState(data: _metrics ??= SystemSampleMapper.metrics(await _service.capabilities()));
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
}

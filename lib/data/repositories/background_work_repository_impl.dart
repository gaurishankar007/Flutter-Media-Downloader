import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/platform/background_work/background_work_service.dart';
import 'package:media_tool/domain/models/background_activity.dart';
import 'package:media_tool/domain/repositories/background_work_repository.dart';

@LazySingleton(as: BackgroundWorkRepository)
final class BackgroundWorkRepositoryImpl({
  required final BackgroundWorkService _service,
  required final ErrorHandler _errorHandler,
}) implements BackgroundWorkRepository {
  BackgroundActivity? _shown;
  bool _askedPermission = false;

  @override
  Stream<String> get cancelRequests => _service.cancelRequests;

  @override
  FutureVoid requestNotificationPermission() =>
      _errorHandler.execute(action: 'backgroundWork.requestPermission', () async {
        if (!_askedPermission) {
          _askedPermission = true;
          await _service.requestNotificationPermission();
        }
        return const SuccessState.nil();
      });

  @override
  FutureVoid update(BackgroundActivity? activity) => _errorHandler.execute(action: 'backgroundWork.update', () async {
    // Progress arrives many times a second; only real changes reach the platform.
    if (activity == _shown) {
      return const SuccessState.nil();
    }
    final wasShown = _shown != null;
    _shown = activity;
    if (activity != null) {
      await _service.show(activity);
    } else if (wasShown) {
      await _service.stop();
    }
    return const SuccessState.nil();
  });
}

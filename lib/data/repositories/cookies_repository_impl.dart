import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/data/services/local/cookies_local_service.dart';
import 'package:media_tool/data/services/platform/file_picker_service.dart';
import 'package:media_tool/domain/models/site.dart';
import 'package:media_tool/domain/models/site_cookies.dart';
import 'package:media_tool/domain/repositories/cookies_repository.dart';

@LazySingleton(as: CookiesRepository)
final class CookiesRepositoryImpl({
  required final CookiesLocalService _localService,
  required final FilePickerService _picker,
  required final ErrorHandler _errorHandler,
}) implements CookiesRepository {
  @override
  bool get supportsBrowserCookies => Platform.isMacOS;

  @override
  FutureList<SiteCookies> list() => _localService.list();

  @override
  FutureData<SiteCookies?> import(Site site) async {
    final picked = await _errorHandler.execute(action: 'cookies.pick', () async {
      return SuccessState(data: await _picker.pickFile());
    });
    if (picked case final FailureState<String?> failure) {
      return failure.retype();
    }
    final path = picked.data;
    if (path == null) {
      return const SuccessState(data: null);
    }
    try {
      final saved = await _localService.save(site, path);
      return saved.mapData<SiteCookies?>((data) => data);
    } finally {
      // The picker's copy of the file mustn't linger in the cache.
      await _errorHandler.executeSafe(_picker.clearTemporaryFiles);
    }
  }

  @override
  FutureVoid remove(Site site) => _localService.remove(site);
}

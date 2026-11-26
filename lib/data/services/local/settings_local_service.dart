import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:media_tool/core/clients/database/app_database.dart';
import 'package:media_tool/core/data/states/data_state.dart';
import 'package:media_tool/core/errors/error_handler.dart';
import 'package:media_tool/core/types/types.dart';

abstract interface class SettingsLocalService {
  /// The stored settings JSON, or `null` on first launch.
  FutureData<JsonMap?> readSettings();

  FutureVoid writeSettings(JsonMap json);
}

@LazySingleton(as: SettingsLocalService)
final class SettingsLocalServiceImpl({required final AppDatabase _database, required final ErrorHandler _errorHandler})
    implements SettingsLocalService {
  static const _settingsKey = 'settings';

  @override
  FutureData<JsonMap?> readSettings() => _errorHandler.execute(action: 'settings.read', () async {
    final table = _database.keyValueLocal;
    final selectStatement = table.select()..where((t) => t.key.equals(_settingsKey));
    final row = await selectStatement.getSingleOrNull();
    final json = row == null ? null : jsonDecode(row.value) as JsonMap;
    return SuccessState(data: json);
  });

  @override
  FutureVoid writeSettings(JsonMap json) => _errorHandler.execute(action: 'settings.write', () async {
    final table = _database.keyValueLocal;
    final row = KeyValueLocalCompanion.insert(key: _settingsKey, value: jsonEncode(json));
    await table.insertOnConflictUpdate(row);
    return const SuccessState.nil();
  });
}

import 'package:media_tool/core/types/types.dart';
import 'package:media_tool/domain/models/app_settings.dart';

abstract interface class SettingsRepository {
  /// The settings loaded by [load], or defaults before that.
  AppSettings get current;

  /// Reads the stored settings into [current]. Called once at startup.
  FutureData<AppSettings> load();

  /// [current] after every successful [update], so changes apply everywhere.
  Stream<AppSettings> watch();

  /// Applies [change] to [current] and stores the result.
  FutureData<AppSettings> update(AppSettings Function(AppSettings settings) change);
}

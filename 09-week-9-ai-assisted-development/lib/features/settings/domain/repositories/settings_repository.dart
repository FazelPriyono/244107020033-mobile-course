import '../../../../core/failures.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<({AppSettings settings, Failure? failure})> getSettings();
  Future<({bool success, Failure? failure})> setDarkMode(bool isDark);
  Future<({bool success, Failure? failure})> markOpenedNow();
}

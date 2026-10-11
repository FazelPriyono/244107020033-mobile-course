import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({Future<SharedPreferences> Function()? getPrefs})
      : _getPrefs = getPrefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _getPrefs;
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  @override
  Future<({AppSettings settings, Failure? failure})> getSettings() async {
    try {
      final prefs = await _getPrefs();
      final isDark = prefs.getBool(_darkModeKey) ?? false;
      final lastOpenedStr = prefs.getString(_lastOpenedKey);
      final lastOpened = lastOpenedStr != null
          ? DateTime.tryParse(lastOpenedStr)
          : null;
      return (
        settings: AppSettings(isDarkMode: isDark, lastOpenedAt: lastOpened),
        failure: null,
      );
    } catch (e) {
      return (
        settings: const AppSettings(isDarkMode: false),
        failure: LocalFailure('Gagal memuat pengaturan: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> setDarkMode(bool isDark) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_darkModeKey, isDark);
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal menyimpan tema: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> markOpenedNow() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal mencatat riwayat buka: $e'),
      );
    }
  }
}

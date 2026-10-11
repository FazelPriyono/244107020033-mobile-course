import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/settings/domain/entities/app_settings.dart';
import 'package:week5_offline_notes/features/settings/domain/repositories/settings_repository.dart';
import 'package:week5_offline_notes/features/settings/domain/usecases/get_settings.dart';
import 'package:week5_offline_notes/features/settings/domain/usecases/toggle_theme_mode.dart';

class FakeSettingsRepository implements SettingsRepository {
  bool currentDark = false;
  bool shouldFail = false;

  @override
  Future<({AppSettings settings, Failure? failure})> getSettings() async {
    if (shouldFail) {
      return (
        settings: const AppSettings(isDarkMode: false),
        failure: const LocalFailure('Simulasi error settings'),
      );
    }
    return (
      settings: AppSettings(isDarkMode: currentDark, lastOpenedAt: DateTime(2026, 10, 12)),
      failure: null,
    );
  }

  @override
  Future<({bool success, Failure? failure})> setDarkMode(bool isDark) async {
    if (shouldFail) {
      return (success: false, failure: const LocalFailure('Simulasi gagal set dark mode'));
    }
    currentDark = isDark;
    return (success: true, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> markOpenedNow() async {
    return (success: true, failure: null);
  }
}

void main() {
  group('Settings Feature Domain Tests', () {
    test('GetSettings mengembalikan entity AppSettings murni', () async {
      final repo = FakeSettingsRepository()..currentDark = true;
      final useCase = GetSettings(repo);

      final result = await useCase.call();
      expect(result.failure, isNull);
      expect(result.settings.isDarkMode, isTrue);
      expect(result.settings.lastOpenedAt, isNotNull);
    });

    test('ToggleThemeMode membalik nilai state dark mode', () async {
      final repo = FakeSettingsRepository()..currentDark = false;
      final useCase = ToggleThemeMode(repo);

      final result1 = await useCase.call(false);
      expect(result1.failure, isNull);
      expect(result1.isDark, isTrue);
      expect(repo.currentDark, isTrue);

      final result2 = await useCase.call(true);
      expect(result2.failure, isNull);
      expect(result2.isDark, isFalse);
      expect(repo.currentDark, isFalse);
    });

    test('ToggleThemeMode mempertahankan mode lama saat repository gagal', () async {
      final repo = FakeSettingsRepository()..shouldFail = true;
      final useCase = ToggleThemeMode(repo);

      final result = await useCase.call(false);
      expect(result.failure, isA<LocalFailure>());
      expect(result.isDark, isFalse);
    });
  });
}

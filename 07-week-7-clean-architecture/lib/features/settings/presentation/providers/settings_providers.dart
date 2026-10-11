import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/toggle_theme_mode.dart';

// Data layer: repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

// Domain layer: use cases
final getSettingsUseCaseProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final toggleThemeModeUseCaseProvider = Provider<ToggleThemeMode>((ref) {
  return ToggleThemeMode(ref.watch(settingsRepositoryProvider));
});

// Presentation layer: app settings info provider
final settingsInfoProvider = FutureProvider<AppSettings>((ref) async {
  final result = await ref.watch(getSettingsUseCaseProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.settings;
});

// Presentation layer: Dark mode notifier
final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref.watch(getSettingsUseCaseProvider).call();
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return result.settings.isDarkMode;
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(toggleThemeModeUseCaseProvider);
      final result = await useCase.call(current);
      if (result.failure != null) {
        throw Exception(result.failure!.message);
      }
      return result.isDark;
    });
  }
}

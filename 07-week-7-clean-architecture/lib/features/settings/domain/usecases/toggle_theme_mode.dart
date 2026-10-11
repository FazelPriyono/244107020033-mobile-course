import '../../../../core/failures.dart';
import '../repositories/settings_repository.dart';

class ToggleThemeMode {
  const ToggleThemeMode(this._repository);
  final SettingsRepository _repository;

  Future<({bool isDark, Failure? failure})> call(bool currentMode) async {
    final nextMode = !currentMode;
    final result = await _repository.setDarkMode(nextMode);
    if (result.failure != null) {
      return (isDark: currentMode, failure: result.failure);
    }
    return (isDark: nextMode, failure: null);
  }
}

import '../../../../core/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  const GetSettings(this._repository);
  final SettingsRepository _repository;

  Future<({AppSettings settings, Failure? failure})> call() {
    return _repository.getSettings();
  }
}

import '../../../../core/failures.dart';

abstract class AiRepository {
  Future<({String? reply, Failure? failure})> askAi(String question);
  Future<String?> getApiKey();
  Future<void> saveApiKey(String key);
}

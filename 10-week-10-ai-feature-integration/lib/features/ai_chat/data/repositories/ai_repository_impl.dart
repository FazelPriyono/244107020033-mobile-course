import '../../../../core/failures.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({AiRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? AiRemoteDatasource();

  final AiRemoteDatasource _remoteDatasource;

  @override
  Future<({String? reply, Failure? failure})> askAi(String question) async {
    try {
      final reply = await _remoteDatasource.ask(question);
      return (reply: reply, failure: null);
    } catch (e) {
      return (
        reply: null,
        failure: NetworkFailure('Gagal memproses pesan AI: $e'),
      );
    }
  }

  @override
  Future<String?> getApiKey() => _remoteDatasource.getApiKey();

  @override
  Future<void> saveApiKey(String key) => _remoteDatasource.saveApiKey(key);
}

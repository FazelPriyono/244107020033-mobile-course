import '../../../../core/failures.dart';
import '../repositories/ai_repository.dart';

class AskAi {
  const AskAi(this._repository);
  final AiRepository _repository;

  Future<({String? reply, Failure? failure})> call(String question) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) {
      return (
        reply: null,
        failure: const ValidationFailure('Pertanyaan tidak boleh kosong'),
      );
    }

    return _repository.askAi(cleanQuestion);
  }
}

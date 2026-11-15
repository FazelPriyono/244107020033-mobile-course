import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/ai_chat/domain/repositories/ai_repository.dart';
import 'package:week5_offline_notes/features/ai_chat/domain/usecases/ask_ai.dart';

class FakeAiRepository implements AiRepository {
  FakeAiRepository({this.fail = false, this.simulatedReply});

  final bool fail;
  final String? simulatedReply;
  String? lastQuestion;
  String? storedApiKey;

  @override
  Future<({String? reply, Failure? failure})> askAi(String question) async {
    lastQuestion = question;
    if (fail) {
      return (
        reply: null,
        failure: const NetworkFailure('Gagal terhubung ke AI API'),
      );
    }
    return (
      reply: simulatedReply ?? 'Respons simulasi untuk: $question',
      failure: null,
    );
  }

  @override
  Future<String?> getApiKey() async => storedApiKey;

  @override
  Future<void> saveApiKey(String key) async {
    storedApiKey = key;
  }
}

void main() {
  group('AskAi Domain UseCase Tests', () {
    test('gagal validasi jika pertanyaan kosong atau hanya spasi', () async {
      final fakeRepo = FakeAiRepository();
      final askAi = AskAi(fakeRepo);

      final result1 = await askAi('');
      expect(result1.reply, isNull);
      expect(result1.failure, isA<ValidationFailure>());
      expect(result1.failure!.message, contains('tidak boleh kosong'));

      final result2 = await askAi('     ');
      expect(result2.reply, isNull);
      expect(result2.failure, isA<ValidationFailure>());
    });

    test(
      'berhasil memanggil repository dengan pertanyaan valid yang di-trim',
      () async {
        final fakeRepo = FakeAiRepository(
          simulatedReply: 'Tips membuat catatan efektif',
        );
        final askAi = AskAi(fakeRepo);

        final result = await askAi('   Bagaimana tips membuat catatan?   ');
        expect(result.failure, isNull);
        expect(result.reply, equals('Tips membuat catatan efektif'));
        expect(
          fakeRepo.lastQuestion,
          equals('Bagaimana tips membuat catatan?'),
        );
      },
    );

    test(
      'meneruskan failure dari repository tanpa melempar exception',
      () async {
        final fakeRepo = FakeAiRepository(fail: true);
        final askAi = AskAi(fakeRepo);

        final result = await askAi('Tanya AI saat server down');
        expect(result.reply, isNull);
        expect(result.failure, isA<NetworkFailure>());
        expect(result.failure!.message, contains('Gagal terhubung'));
      },
    );
  });
}

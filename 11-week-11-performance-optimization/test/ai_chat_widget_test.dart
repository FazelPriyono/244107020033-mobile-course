import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/core/failures.dart';
import 'package:week11_performance_optimization/features/ai_chat/domain/repositories/ai_repository.dart';
import 'package:week11_performance_optimization/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:week11_performance_optimization/features/ai_chat/presentation/providers/ai_chat_providers.dart';

class MockAiRepository implements AiRepository {
  String? apiKey;

  @override
  Future<({String? reply, Failure? failure})> askAi(String question) async {
    return (reply: 'Jawaban simulasi asisten untuk: $question', failure: null);
  }

  @override
  Future<String?> getApiKey() async => apiKey ?? 'dummy-key';

  @override
  Future<void> saveApiKey(String key) async {
    apiKey = key;
  }
}

void main() {
  group('AiChatPage Widget Tests', () {
    testWidgets('menampilkan pesan sambutan awal dan input bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(MockAiRepository()),
          ],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      expect(find.text('AI Note Assistant'), findsOneWidget);
      expect(
        find.textContaining('Halo! Saya asisten catatan AI Anda'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('mengirim pesan menampilkan bubble pengguna dan respons AI', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(MockAiRepository()),
          ],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      await tester.enterText(
        find.byType(TextField),
        'Bagaimana cara menstrukturkan catatan?',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(
        find.text('Bagaimana cara menstrukturkan catatan?'),
        findsOneWidget,
      );
      expect(find.textContaining('Jawaban simulasi asisten'), findsOneWidget);
    });

    testWidgets('menekan ikon kunci membuka dialog pengaturan API key', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(MockAiRepository()),
          ],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      await tester.tap(find.byIcon(Icons.vpn_key_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan API Key AI'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}

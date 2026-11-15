import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/ask_ai.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl();
});

final askAiUseCaseProvider = Provider<AskAi>((ref) {
  return AskAi(ref.watch(aiRepositoryProvider));
});

class AiChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        id: 'welcome',
        content: 'Halo! Saya asisten catatan AI Anda. Ada yang bisa saya bantu terkait ide catatan, ringkasan, atau tips produktivitas?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<void> sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];

    ref.read(aiLoadingProvider.notifier).setLoading(true);
    try {
      final askAi = ref.read(askAiUseCaseProvider);
      final result = await askAi(prompt);

      if (result.failure != null) {
        final errorMsg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          content: 'Terjadi kesalahan: ${result.failure!.message}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        state = [...state, errorMsg];
      } else {
        final aiMsg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          content: result.reply ?? 'Tidak ada tanggapan dari asisten.',
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = [...state, aiMsg];
      }
    } finally {
      ref.read(aiLoadingProvider.notifier).setLoading(false);
    }
  }

  void clearChat() {
    state = [
      ChatMessage(
        id: 'welcome',
        content: 'Percakapan telah direset. Ada yang bisa saya bantu?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, List<ChatMessage>>(
  AiChatNotifier.new,
);

class AiLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) => state = val;
}

final aiLoadingProvider = NotifierProvider<AiLoadingNotifier, bool>(
  AiLoadingNotifier.new,
);

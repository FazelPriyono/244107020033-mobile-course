import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiRemoteDatasource {
  AiRemoteDatasource({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;
  static const _apiKeyStorageKey = 'ai_api_key';
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String?> getApiKey() async {
    return _storage.read(key: _apiKeyStorageKey);
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _apiKeyStorageKey, value: key);
  }

  Future<String> ask(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return _generateOfflineFallback(question);
    }

    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text': 'Kamu adalah asisten catatan cerdas (AI Note Assistant). Jawab secara ringkas, ramah, dalam Bahasa Indonesia, dan fokus membantu manajemen catatan, produktivitas, serta pembelajaran.',
              },
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': question},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        return 'Maaf, model tidak menghasilkan respons teks.';
      } else {
        return _generateOfflineFallback(
          question,
          reason:
              'Layanan API merespons dengan status ${response.statusCode}. Menggunakan mode offline.',
        );
      }
    } catch (e) {
      return _generateOfflineFallback(
        question,
        reason: 'Tidak dapat terhubung ke cloud AI ($e). Mode offline aktif.',
      );
    }
  }

  String _generateOfflineFallback(String question, {String? reason}) {
    final lower = question.toLowerCase();
    String tips = '';
    if (lower.contains('catatan') || lower.contains('note')) {
      tips = 'Tips: Buat catatan secara teratur dan gunakan judul yang jelas untuk mempermudah pencarian.';
    } else if (lower.contains('clean') || lower.contains('arsitektur')) {
      tips = 'Clean Architecture memisahkan kode menjadi layer Presentation, Domain (murni Dart), dan Data.';
    } else if (lower.contains('riverpod') || lower.contains('state')) {
      tips = 'Gunakan Notifier dan Provider pada Riverpod untuk state management yang reaktif dan mudah diuji.';
    } else {
      tips = 'Asisten siap membantu membuat ringkasan, ide judul catatan, atau menyusun jadwal produktif Anda.';
    }

    if (reason != null) {
      return '$tips\n\n(Catatan: $reason)';
    }
    return '$tips\n\n(Catatan: API key belum diatur. Masukkan API key pada menu Pengaturan AI untuk jawaban online).';
  }
}

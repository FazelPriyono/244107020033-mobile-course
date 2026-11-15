import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiRemoteDatasource {
  AiRemoteDatasource({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;
  static const _apiKeyStorageKey = 'ai_api_key';

  /// Cache API key di memori.
  ///
  /// Sebelum optimasi, setiap pesan memicu dua platform channel
  /// (`FlutterSecureStorage.read` + `SharedPreferences.getInstance`), sehingga
  /// ada latensi tambahan sebelum request jaringan dikirim.
  String? _cachedApiKey;

  // Daftar model aktif Google Gemini yang terverifikasi cepat dan stabil:
  // 1. gemini-3.5-flash-lite (respons super cepat ~1 detik)
  // 2. gemini-3.6-flash (kualitas jawaban tinggi dan stabil ~2 detik)
  // 3. gemini-3.5-flash & gemini-3.8-flash sebagai fallback
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-flash-lite-latest',
  ];

  Future<String?> getApiKey() async {
    final cached = _cachedApiKey;
    if (cached != null) return cached;

    try {
      final secureVal = await _storage.read(key: _apiKeyStorageKey);
      if (secureVal != null && secureVal.trim().isNotEmpty) {
        return _cachedApiKey = secureVal.trim();
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefVal = prefs.getString(_apiKeyStorageKey);
      if (prefVal != null && prefVal.trim().isNotEmpty) {
        return _cachedApiKey = prefVal.trim();
      }
    } catch (_) {}

    return null;
  }

  Future<void> saveApiKey(String key) async {
    final cleanKey = key.trim();
    _cachedApiKey = cleanKey.isEmpty ? null : cleanKey;
    try {
      await _storage.write(key: _apiKeyStorageKey, value: cleanKey);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyStorageKey, cleanKey);
    } catch (_) {}
  }

  Future<String> ask(String question) async {
    final rawKey = await getApiKey();
    if (rawKey == null || rawKey.trim().isEmpty) {
      return _generateOfflineFallback(
        question,
        reason: 'API key belum diatur. Tap ikon kunci di AppBar untuk memasukkan key.',
      );
    }

    final apiKey = rawKey.trim();

    // Validasi format: Menerima format klasik (AIza...) maupun format Authorization Key baru Google AI Studio (AQ....)
    if (!apiKey.startsWith('AIza') && !apiKey.startsWith('AQ.')) {
      final prefix = apiKey.length >= 6 ? apiKey.substring(0, 6) : apiKey;
      return _generateOfflineFallback(
        question,
        reason:
            'Format kunci "$prefix..." tidak dikenali. Pastikan menyalin Google API key dari aistudio.google.com/app/apikey (diawali "AQ." atau "AIza").',
      );
    }

    String lastError = '';

    for (final model in _models) {
      final endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
      try {
        final uri = Uri.parse(endpoint);
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {
                        'text':
                            'Kamu adalah asisten catatan cerdas (AI Note Assistant). Jawab secara ringkas, ramah, dalam Bahasa Indonesia, dan fokus membantu manajemen catatan, produktivitas, serta pembelajaran.\n\nPertanyaan: $question',
                      },
                    ],
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
          return 'Model $model berhasil merespons tetapi tidak menghasilkan teks.';
        } else {
          try {
            final errData = jsonDecode(response.body);
            if (errData['error'] != null &&
                errData['error']['message'] != null) {
              lastError =
                  '[$model HTTP ${response.statusCode}] ${errData['error']['message']}';
            } else {
              lastError = '[$model HTTP ${response.statusCode}]';
            }
          } catch (_) {
            lastError = '[$model HTTP ${response.statusCode}] ${response.body}';
          }

          // Jika API key salah (400) atau akses ditolak (403), tidak perlu mencoba model lain
          if (response.statusCode == 400 || response.statusCode == 403) {
            break;
          }

          // Jika 503 (server sibuk) atau 404 (model dialihkan), lanjut ke model berikutnya
          continue;
        }
      } on TimeoutException {
        lastError = '[$model] Waktu permintaan habis (timeout 8 detik).';
      } catch (e) {
        lastError = '[$model] $e';
      }
    }

    return _generateOfflineFallback(
      question,
      reason: 'Layanan API merespons: $lastError. Menggunakan mode offline.',
    );
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

    if (reason != null && reason.isNotEmpty) {
      return '$tips\n\n(Catatan: $reason)';
    }
    return '$tips\n\n(Catatan: API key belum diatur. Masukkan API key pada menu Pengaturan AI untuk jawaban online).';
  }
}

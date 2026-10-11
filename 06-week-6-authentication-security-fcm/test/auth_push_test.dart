import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper murni yang bisa diuji tanpa Firebase.
// Salinan dari push_service.dart — sesuai instruksi modul §7.
// ---------------------------------------------------------------------------
String routeFromMessage(Map<String, dynamic> data) {
  final route = (data['route'] as String?) ?? '/';
  return route.startsWith('/') ? route : '/$route';
}

// ---------------------------------------------------------------------------
// Fake token store untuk uji logika sesi tanpa FlutterSecureStorage.
// ---------------------------------------------------------------------------
class FakeTokenStore {
  String? access;
  String? refresh;

  void save({required String a, required String r}) {
    access = a;
    refresh = r;
  }

  void clear() {
    access = null;
    refresh = null;
  }
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------
void main() {
  group('routeFromMessage', () {
    test('mengembalikan "/" jika data kosong', () {
      expect(routeFromMessage({}), '/');
    });

    test('menambahkan slash jika route tidak diawali "/"', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('tidak menggandakan slash jika sudah ada "/"', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });
  });

  group('data payload', () {
    test('membawa id pengumuman dengan benar', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });
  });

  group('logika sesi (FakeTokenStore)', () {
    test('token ada → login dianggap aktif', () {
      final store = FakeTokenStore()..access = 'mock-access';
      expect(store.access != null, isTrue);
    });

    test('token null → login dianggap tidak aktif', () {
      final store = FakeTokenStore();
      expect(store.access != null, isFalse);
    });

    test('clear() menghapus kedua token', () {
      final store = FakeTokenStore()
        ..save(a: 'acc', r: 'ref');
      store.clear();
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    });
  });

  group('logika refresh token', () {
    test('refresh kosong → perlu login ulang', () {
      final store = FakeTokenStore()..refresh = '';
      final needsLogin = (store.refresh ?? '').isEmpty;
      expect(needsLogin, isTrue);
    });

    test('refresh ada → tidak perlu login ulang', () {
      final store = FakeTokenStore()..refresh = 'valid-refresh';
      final needsLogin = (store.refresh ?? '').isEmpty;
      expect(needsLogin, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/format.dart';

void main() {
  group('Core Pure Format & Route Parser Tests', () {
    test('formatDisplayDate memformat DateTime ke format DD/MM/YYYY HH:mm', () {
      final dt = DateTime(2026, 10, 12, 14, 5);
      final formatted = formatDisplayDate(dt);
      expect(formatted, '12/10/2026 14:05');
    });

    test('parseRouteId mengurai string angka dan menangani null/kosong/invalid', () {
      expect(parseRouteId('42'), 42);
      expect(parseRouteId(' 100 '), 100);
      expect(parseRouteId(''), 0);
      expect(parseRouteId(null), 0);
      expect(parseRouteId('abc'), 0);
    });

    test('formatNoteSnippet memotong teks panjang dan membersihkan newline', () {
      const multiline = 'Baris satu\nBaris dua\nBaris tiga';
      final snippet = formatNoteSnippet(body: multiline, maxLength: 20);
      expect(snippet.contains('\n'), isFalse);
      expect(snippet, 'Baris satu Baris dua...');

      expect(formatNoteSnippet(body: ''), 'Tidak ada isi tambahan');
    });
  });
}

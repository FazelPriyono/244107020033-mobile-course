import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_quality_assurance/core/validators.dart';

void main() {
  group('isValidNoteTitle', () {
    test('menerima judul yang berisi teks', () {
      // Arrange
      const title = 'Belajar Flutter';

      // Act
      final result = isValidNoteTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('menerima judul dengan spasi di awal dan akhir', () {
      expect(isValidNoteTitle('  Review Bab 12  '), isTrue);
    });

    test('menolak string kosong', () {
      expect(isValidNoteTitle(''), isFalse);
    });

    test('menolak teks yang hanya berisi spasi, tab, dan newline', () {
      expect(isValidNoteTitle('   '), isFalse);
      expect(isValidNoteTitle('\t'), isFalse);
      expect(isValidNoteTitle('\n  \n'), isFalse);
    });

    test('menolak karakter tak terlihat saja (zero-width space)', () {
      // Kasus tepi: secara visual kosong, tetapi bukan whitespace ASCII.
      // Aturan bisnis saat ini menganggapnya sebagai judul valid; test ini
      // mendokumentasikan perilaku tersebut agar perubahan aturan terdeteksi.
      expect(isValidNoteTitle('\u200B'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week11_performance_optimization/features/notes/domain/usecases/search_notes.dart';

void main() {
  late SearchNotes searchNotes;
  late List<Note> sampleNotes;

  setUp(() {
    searchNotes = const SearchNotes();
    final now = DateTime(2026, 11, 15);
    sampleNotes = [
      Note(
        id: 1,
        title: 'Daftar Belanja Mingguan',
        body: 'Susu, roti, dan telur untuk sarapan',
        updatedAt: now,
      ),
      Note(
        id: 2,
        title: 'Rencana Belanja Bulanan',
        body: 'Sabun, deterjen, dan minyak goreng',
        updatedAt: now,
      ),
      Note(
        id: 3,
        title: 'Review Bab Clean Architecture',
        body: 'Pelajari Dependency Inversion dan Use Case',
        updatedAt: now,
      ),
      Note(
        id: 4,
        title: 'Praktikum Flutter Riverpod',
        body: 'State management dengan Provider dan Notifier',
        updatedAt: now,
      ),
    ];
  });

  group('SearchNotes Domain UseCase Tests', () {
    test('query kosong mengembalikan seluruh daftar catatan asli', () {
      final result = searchNotes(notes: sampleNotes, query: '');
      expect(result, hasLength(sampleNotes.length));
      expect(result, equals(sampleNotes));
    });

    test('filter abaikan huruf besar/kecil (case-insensitive)', () {
      final result = searchNotes(notes: sampleNotes, query: 'belanja');
      expect(result, hasLength(2));
      expect(result.map((n) => n.id), containsAll([1, 2]));

      final uppercaseResult = searchNotes(notes: sampleNotes, query: 'BELANJA');
      expect(uppercaseResult, hasLength(2));
    });

    test('query tak cocok kembalikan kosong', () {
      final result = searchNotes(notes: sampleNotes, query: 'zzz-tak-ada');
      expect(result, isEmpty);
    });

    test('query dengan whitespace di-trim dengan benar', () {
      final result = searchNotes(notes: sampleNotes, query: '   clean   ');
      expect(result, hasLength(1));
      expect(result.first.id, equals(3));
    });

    test('pencarian mencocokkan kata pada isi catatan (body)', () {
      final result = searchNotes(notes: sampleNotes, query: 'deterjen');
      expect(result, hasLength(1));
      expect(result.first.id, equals(2));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/get_notes.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({int count, Failure? failure})> countDirty() {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() {
    throw UnimplementedError();
  }
}

void main() {
  group('GetNotes UseCase Test (Pure Domain)', () {
    test('GetNotes meneruskan daftar dari repository', () async {
      final repo = FakeNoteRepository(items: [
        Note(title: 'A', updatedAt: DateTime(2026, 9, 27)),
      ]);
      final result = await GetNotes(repo).call();
      expect(result.failure, isNull);
      expect(result.notes.length, 1);
      expect(result.notes.first.title, 'A');
    });

    test('GetNotes meneruskan failure tanpa melempar exception', () async {
      final repo = FakeNoteRepository(fail: true);
      final result = await GetNotes(repo).call();
      expect(result.failure, isA<LocalFailure>());
      expect(result.notes, isEmpty);
      expect(result.failure!.message, contains('db locked'));
    });
  });
}

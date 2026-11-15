import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/core/failures.dart';
import 'package:week11_performance_optimization/features/notes/data/repositories/cached_note_repository.dart';
import 'package:week11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week11_performance_optimization/features/notes/domain/repositories/note_repository.dart';

class _FakeSource implements NoteRepository {
  _FakeSource(this.notes);

  List<Note> notes;
  int fetchCalls = 0;
  int getByIdCalls = 0;
  int countCalls = 0;
  int addCalls = 0;
  int deleteCalls = 0;
  int updateCalls = 0;
  int markCalls = 0;
  int? lastLimit;
  int? lastOffset;
  bool failFetch = false;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int limit = 1000,
    int offset = 0,
  }) async {
    fetchCalls++;
    lastLimit = limit;
    lastOffset = offset;
    if (failFetch) {
      return (notes: const <Note>[], failure: const LocalFailure('boom'));
    }
    final slice = notes.skip(offset).take(limit).toList();
    return (notes: slice, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) async {
    getByIdCalls++;
    for (final note in notes) {
      if (note.id == id) return (note: note, failure: null);
    }
    return (note: null, failure: const LocalFailure('tidak ditemukan'));
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 15),
    );
    notes = [...notes, note];
    return (note: note, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    updateCalls++;
    return (success: true, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    deleteCalls++;
    notes = notes.where((note) => note.id != id).toList();
    return (success: true, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    countCalls++;
    return (count: notes.where((note) => note.dirty).length, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    markCalls++;
    return (success: true, failure: null);
  }
}

Note _note(int id, {bool dirty = false}) => Note(
  id: id,
  title: 'Catatan $id',
  body: 'Isi catatan $id',
  updatedAt: DateTime(2026, 11, 15, 10, id),
  dirty: dirty,
);

void main() {
  group('CachedNoteRepository (Cache-First)', () {
    test('fetchNotes kedua disajikan dari cache tanpa query ulang', () async {
      final source = _FakeSource([_note(1), _note(2)]);
      final repository = CachedNoteRepository(source);

      final first = await repository.fetchNotes(limit: 50);
      final second = await repository.fetchNotes(limit: 50);

      expect(first.notes.map((n) => n.id), [1, 2]);
      expect(second.notes.map((n) => n.id), [1, 2]);
      expect(source.fetchCalls, 1);
    });

    test('limit yang lebih besar dari cache akan re-query ke sumber', () async {
      final source = _FakeSource([_note(1), _note(2), _note(3)]);
      final repository = CachedNoteRepository(source);

      await repository.fetchNotes(limit: 2);
      await repository.fetchNotes(limit: 10);

      expect(source.fetchCalls, 2);
      expect(source.lastLimit, 10);
    });

    test('getNoteById memakai indeks cache setelah fetchNotes', () async {
      final source = _FakeSource([_note(1), _note(2)]);
      final repository = CachedNoteRepository(source);

      await repository.fetchNotes();
      final result = await repository.getNoteById(2);

      expect(result.note?.title, 'Catatan 2');
      expect(source.getByIdCalls, 0);
    });

    test('mutasi addNote meng-invalidasi cache', () async {
      final source = _FakeSource([_note(1)]);
      final repository = CachedNoteRepository(source);

      await repository.fetchNotes();
      await repository.addNote(title: 'Baru');
      await repository.fetchNotes();

      expect(source.addCalls, 1);
      expect(source.fetchCalls, 2);
    });

    test(
      'mutasi deleteNote meng-invalidasi cache daftar dan countDirty',
      () async {
        final source = _FakeSource([
          _note(1, dirty: true),
          _note(2, dirty: true),
        ]);
        final repository = CachedNoteRepository(source);

        await repository.countDirty();
        await repository.countDirty();
        expect(source.countCalls, 1);

        await repository.deleteNote(1);
        final afterDelete = await repository.countDirty();

        expect(source.deleteCalls, 1);
        expect(source.countCalls, 2);
        expect(afterDelete.count, 1);
      },
    );

    test(
      'mutasi updateNote dan markAllSynced juga meng-invalidasi cache',
      () async {
        final source = _FakeSource([_note(1)]);
        final repository = CachedNoteRepository(source);

        await repository.fetchNotes();
        await repository.updateNote(_note(1));
        await repository.fetchNotes();
        expect(source.fetchCalls, 2);

        await repository.markAllSynced();
        await repository.fetchNotes();
        expect(source.fetchCalls, 3);
        expect(source.updateCalls, 1);
        expect(source.markCalls, 1);
      },
    );

    test(
      'pagination offset diteruskan dan tidak memakai cache halaman pertama',
      () async {
        final source = _FakeSource([_note(1), _note(2), _note(3), _note(4)]);
        final repository = CachedNoteRepository(source);

        await repository.fetchNotes(limit: 2, offset: 0);
        final secondPage = await repository.fetchNotes(limit: 2, offset: 2);

        expect(secondPage.notes.map((n) => n.id), [3, 4]);
        expect(source.fetchCalls, 2);
        expect(source.lastOffset, 2);
      },
    );

    test('kegagalan fetch tidak disimpan ke cache', () async {
      final source = _FakeSource([_note(1)])..failFetch = true;
      final repository = CachedNoteRepository(source);

      final failed = await repository.fetchNotes();
      expect(failed.failure, isA<LocalFailure>());

      source.failFetch = false;
      final recovered = await repository.fetchNotes();

      expect(recovered.notes.map((n) => n.id), [1]);
      expect(source.fetchCalls, 2);
    });
  });
}

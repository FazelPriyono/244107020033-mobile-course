import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';

class FakeAddNoteRepository implements NoteRepository {
  Note? savedNote;

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: 99,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 10, 12),
      dirty: true,
    );
    savedNote = note;
    return (note: note, failure: null);
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() => throw UnimplementedError();

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) => throw UnimplementedError();

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) => throw UnimplementedError();

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) => throw UnimplementedError();

  @override
  Future<({int count, Failure? failure})> countDirty() => throw UnimplementedError();

  @override
  Future<({bool success, Failure? failure})> markAllSynced() => throw UnimplementedError();
}

void main() {
  group('AddNote UseCase Test (Validation & Domain Logic)', () {
    test('Gagal validasi jika judul kosong atau hanya spasi', () async {
      final repo = FakeAddNoteRepository();
      final useCase = AddNote(repo);

      final resultEmpty = await useCase.call(title: '');
      expect(resultEmpty.failure, isA<ValidationFailure>());
      expect(resultEmpty.failure!.message, 'Judul catatan tidak boleh kosong');
      expect(repo.savedNote, isNull);

      final resultSpaces = await useCase.call(title: '   ');
      expect(resultSpaces.failure, isA<ValidationFailure>());
      expect(repo.savedNote, isNull);
    });

    test('Berhasil menyimpan catatan dengan judul valid dan melakukan trim', () async {
      final repo = FakeAddNoteRepository();
      final useCase = AddNote(repo);

      final result = await useCase.call(
        title: ' Belajar Clean Architecture ',
        body: ' Separation of concerns ',
      );

      expect(result.failure, isNull);
      expect(result.note, isNotNull);
      expect(result.note!.title, 'Belajar Clean Architecture');
      expect(result.note!.body, 'Separation of concerns');
      expect(repo.savedNote?.title, 'Belajar Clean Architecture');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/update_note.dart';

class FakeUpdateNoteRepository implements NoteRepository {
  FakeUpdateNoteRepository({this.fail = false});

  final bool fail;
  Note? updatedNote;

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    if (fail) {
      return (
        success: false,
        failure: const LocalFailure('Gagal memperbarui catatan (simulasi)'),
      );
    }
    updatedNote = note;
    return (success: true, failure: null);
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() =>
      throw UnimplementedError();

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) =>
      throw UnimplementedError();

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) => throw UnimplementedError();

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) =>
      throw UnimplementedError();

  @override
  Future<({int count, Failure? failure})> countDirty() =>
      throw UnimplementedError();

  @override
  Future<({bool success, Failure? failure})> markAllSynced() =>
      throw UnimplementedError();
}

Note buildNote({String title = 'Judul', String body = 'Isi'}) {
  return Note(
    id: 1,
    title: title,
    body: body,
    updatedAt: DateTime(2026, 11, 2),
    dirty: true,
  );
}

void main() {
  group('UpdateNote UseCase Test (Validation & Domain Logic)', () {
    test('Gagal validasi jika judul kosong atau hanya spasi', () async {
      final repo = FakeUpdateNoteRepository();
      final useCase = UpdateNote(repo);

      final resultEmpty = await useCase.call(buildNote(title: ''));
      expect(resultEmpty.success, isFalse);
      expect(resultEmpty.failure, isA<ValidationFailure>());
      expect(resultEmpty.failure!.message, 'Judul catatan tidak boleh kosong');
      expect(repo.updatedNote, isNull);

      final resultSpaces = await useCase.call(buildNote(title: '   '));
      expect(resultSpaces.success, isFalse);
      expect(resultSpaces.failure, isA<ValidationFailure>());
      expect(repo.updatedNote, isNull);
    });

    test('Melakukan trim judul dan isi sebelum disimpan', () async {
      final repo = FakeUpdateNoteRepository();
      final useCase = UpdateNote(repo);

      final result = await useCase.call(
        buildNote(title: '  Belanja  ', body: '  Beras dan telur  '),
      );

      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(repo.updatedNote?.title, 'Belanja');
      expect(repo.updatedNote?.body, 'Beras dan telur');
    });

    test(
      'Meneruskan failure dari repository tanpa melempar exception',
      () async {
        final repo = FakeUpdateNoteRepository(fail: true);
        final useCase = UpdateNote(repo);

        final result = await useCase.call(buildNote());

        expect(result.success, isFalse);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure!.message, contains('simulasi'));
      },
    );
  });
}

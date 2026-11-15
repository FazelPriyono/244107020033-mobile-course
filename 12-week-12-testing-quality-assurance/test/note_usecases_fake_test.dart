import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/usecases/add_note.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/usecases/delete_note.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/usecases/get_notes.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/usecases/update_note.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  final sampleNote = Note(
    id: 1,
    title: 'Catatan awal',
    body: 'Isi awal',
    updatedAt: DateTime(2026, 11, 15, 9),
  );

  group('AddNote dengan fake repository', () {
    test('menyimpan catatan dan melakukan trim', () async {
      final fake = FakeNoteRepository();
      final useCase = AddNote(fake);

      final result = await useCase.call(
        title: '  Judul Baru  ',
        body: '  Isi baru  ',
      );

      expect(result.failure, isNull);
      expect(result.note?.title, 'Judul Baru');
      expect(result.note?.body, 'Isi baru');
      expect(fake.addCalls, 1);
      expect(fake.notes.single.title, 'Judul Baru');
    });

    test('tidak memanggil repository saat judul tidak valid', () async {
      final fake = FakeNoteRepository();
      final useCase = AddNote(fake);

      final result = await useCase.call(title: '   ');

      expect(result.failure, isA<ValidationFailure>());
      expect(fake.addCalls, 0);
      expect(fake.notes, isEmpty);
    });

    test('meneruskan kegagalan repository tanpa melempar exception', () async {
      final fake = FakeNoteRepository(
        addFailure: const LocalFailure('disk penuh'),
      );
      final useCase = AddNote(fake);

      final result = await useCase.call(title: 'Judul valid');

      expect(result.note, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, 'disk penuh');
      expect(fake.notes, isEmpty);
    });
  });

  group('GetNotes dengan fake repository', () {
    test('meneruskan daftar catatan dari repository', () async {
      final fake = FakeNoteRepository(notes: [sampleNote]);

      final result = await GetNotes(fake).call();

      expect(result.failure, isNull);
      expect(result.notes.single.title, 'Catatan awal');
      expect(fake.fetchCalls, 1);
    });

    test(
      'meneruskan failure tanpa mengubahnya menjadi daftar kosong',
      () async {
        final fake = FakeNoteRepository(
          fetchFailure: const LocalFailure('database terkunci'),
        );

        final result = await GetNotes(fake).call();

        expect(result.notes, isEmpty);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure?.message, 'database terkunci');
      },
    );
  });

  group('UpdateNote dengan fake repository', () {
    test('memperbarui catatan dan melakukan trim', () async {
      final fake = FakeNoteRepository(notes: [sampleNote]);

      final result = await UpdateNote(fake)
          .call(sampleNote.copyWith(title: '  Judul revisi  '));

      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(fake.notes.single.title, 'Judul revisi');
      expect(fake.updateCalls, 1);
    });

    test('menolak judul kosong sebelum memanggil repository', () async {
      final fake = FakeNoteRepository(notes: [sampleNote]);

      final result = await UpdateNote(fake)
          .call(sampleNote.copyWith(title: '   '));

      expect(result.success, isFalse);
      expect(result.failure, isA<ValidationFailure>());
      expect(fake.updateCalls, 0);
    });

    test('meneruskan kegagalan update dari repository', () async {
      final fake = FakeNoteRepository(
        notes: [sampleNote],
        updateFailure: const LocalFailure('baris terkunci'),
      );

      final result = await UpdateNote(fake).call(sampleNote);

      expect(result.success, isFalse);
      expect(result.failure?.message, 'baris terkunci');
    });
  });

  group('DeleteNote dengan fake repository', () {
    test('menghapus catatan berdasarkan id', () async {
      final fake = FakeNoteRepository(notes: [sampleNote]);

      final result = await DeleteNote(fake).call(1);

      expect(result.success, isTrue);
      expect(fake.notes, isEmpty);
      expect(fake.deleteCalls, 1);
    });

    test('meneruskan kegagalan hapus dari repository', () async {
      final fake = FakeNoteRepository(
        notes: [sampleNote],
        deleteFailure: const LocalFailure('tidak boleh dihapus'),
      );

      final result = await DeleteNote(fake).call(1);

      expect(result.success, isFalse);
      expect(result.failure?.message, 'tidak boleh dihapus');
      expect(fake.notes, hasLength(1));
    });
  });
}

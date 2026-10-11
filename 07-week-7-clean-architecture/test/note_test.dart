import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/data/models/note_model.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false});

  final List<Note> items;
  final bool throwError;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (throwError) {
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (count: items.where((n) => n.dirty).length, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    return (success: true, failure: null);
  }
}

void main() {
  group('NoteModel Data Layer Tests', () {
    test('fromMap aman terhadap field yang hilang dan mengonversi ke default', () {
      final model = NoteModel.fromMap({'title': 'Belanja'});
      expect(model.title, 'Belanja');
      expect(model.body, '');
      expect(model.dirty, isFalse);
    });

    test('flag dirty bertahan pada serialisasi model', () {
      final model = NoteModel(
        title: 'a',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );
      final restored = NoteModel.fromMap(model.toMap());
      expect(restored.dirty, isTrue);
    });

    test('toEntity menghasilkan domain entity murni tanpa method serialisasi', () {
      final model = NoteModel(
        id: 1,
        title: 'Entity Test',
        body: 'Body Test',
        updatedAt: DateTime(2026, 10, 12),
        dirty: true,
      );
      final entity = model.toEntity();
      expect(entity, isA<Note>());
      expect(entity.id, 1);
      expect(entity.title, 'Entity Test');
    });
  });

  group('Presentation Provider DI Wiring Tests', () {
    test('provider sukses dengan repository palsu disuntikkan', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(items: [
              Note(title: 'Tes Clean Arch', updatedAt: DateTime.now()),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notes = await container.read(notesProvider.future);
      expect(notes.length, 1);
      expect(notes.first.title, 'Tes Clean Arch');
    });

    test('provider error menangkap Failure dan melempar Exception ramah UI', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}

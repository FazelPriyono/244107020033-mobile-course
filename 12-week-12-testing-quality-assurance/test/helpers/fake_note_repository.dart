import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/repositories/note_repository.dart';

/// Implementasi tiruan (fake) untuk [NoteRepository].
///
/// Fake dipakai agar unit test dan widget test tidak menyentuh SQLite serta
/// dapat mengendalikan hasil sukses maupun kegagalan secara deterministik.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({
    List<Note>? notes,
    this.fetchFailure,
    this.addFailure,
    this.updateFailure,
    this.deleteFailure,
    this.dirtyCountFailure,
  }) : _notes = [...?notes];

  final List<Note> _notes;
  final Failure? fetchFailure;
  final Failure? addFailure;
  final Failure? updateFailure;
  final Failure? deleteFailure;
  final Failure? dirtyCountFailure;

  int fetchCalls = 0;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int _nextId = 100;

  List<Note> get notes => List.unmodifiable(_notes);

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int limit = 1000,
    int offset = 0,
  }) async {
    fetchCalls++;
    if (fetchFailure != null) {
      return (notes: const <Note>[], failure: fetchFailure);
    }
    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final page = sorted.skip(offset).take(limit).toList();
    return (notes: page, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) async {
    final match = _notes.where((note) => note.id == id);
    if (match.isEmpty) {
      return (
        note: null,
        failure: const LocalFailure('Catatan tidak ditemukan'),
      );
    }
    return (note: match.first, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    if (addFailure != null) {
      return (note: null, failure: addFailure);
    }
    final note = Note(
      id: _nextId++,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 15, 10, addCalls),
      dirty: true,
    );
    _notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    updateCalls++;
    if (updateFailure != null) {
      return (success: false, failure: updateFailure);
    }
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index == -1) {
      return (success: false, failure: const LocalFailure('Catatan tidak ada'));
    }
    _notes[index] = note;
    return (success: true, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    deleteCalls++;
    if (deleteFailure != null) {
      return (success: false, failure: deleteFailure);
    }
    _notes.removeWhere((note) => note.id == id);
    return (success: true, failure: null);
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    if (dirtyCountFailure != null) {
      return (count: 0, failure: dirtyCountFailure);
    }
    return (count: _notes.where((note) => note.dirty).length, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    for (var i = 0; i < _notes.length; i++) {
      _notes[i] = _notes[i].copyWith(dirty: false);
    }
    return (success: true, failure: null);
  }
}

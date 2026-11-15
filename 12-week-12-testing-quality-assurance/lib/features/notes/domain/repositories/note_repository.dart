import '../../../../core/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  /// Mengambil catatan dengan pagination (lazy loading di level data).
  ///
  /// [limit] dan [offset] memungkinkan mengambil sebagian data untuk
  /// menghindari query serta konversi model yang berat pada dataset besar.
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int limit = 1000,
    int offset = 0,
  });
  Future<({Note? note, Failure? failure})> getNoteById(int id);
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });
  Future<({bool success, Failure? failure})> updateNote(Note note);
  Future<({bool success, Failure? failure})> deleteNote(int id);
  Future<({int count, Failure? failure})> countDirty();
  Future<({bool success, Failure? failure})> markAllSynced();
}

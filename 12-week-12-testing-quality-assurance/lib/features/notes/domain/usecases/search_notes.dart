import '../entities/note.dart';

class SearchNotes {
  const SearchNotes();

  List<Note> call({required List<Note> notes, required String query}) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(cleanQuery);
      final bodyMatch = note.body.toLowerCase().contains(cleanQuery);
      return titleMatch || bodyMatch;
    }).toList();
  }
}

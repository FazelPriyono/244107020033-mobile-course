import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

/// Decorator [NoteRepository] dengan strategi Cache-First.
///
/// Manfaat (modul Week 11, bagian optimasi jaringan & caching):
/// - `fetchNotes` halaman pertama disajikan dari cache memori, sehingga query
///   SQLite dan konversi `NoteModel` tidak diulang di setiap rebuild.
/// - `getNoteById` memakai indeks `id -> Note`.
/// - `countDirty` di-cache untuk badge status.
/// - Semua mutasi (add/update/delete/markAllSynced) meng-invalidasi cache.
class CachedNoteRepository implements NoteRepository {
  CachedNoteRepository(this._source);

  final NoteRepository _source;

  List<Note>? _notesCache;
  int _cachedLimit = 0;
  final Map<int, Note> _byIdCache = <int, Note>{};
  int? _dirtyCountCache;

  /// Mengosongkan seluruh cache. Dipanggil setelah ada penulisan ke SQLite.
  void invalidate() {
    _notesCache = null;
    _cachedLimit = 0;
    _byIdCache.clear();
    _dirtyCountCache = null;
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int limit = 1000,
    int offset = 0,
  }) async {
    // Cache-first: halaman pertama dengan limit yang lebih kecil sama dengan
    // data yang pernah diambil bisa langsung disajikan.
    if (offset == 0 && _notesCache != null && limit <= _cachedLimit) {
      return (notes: List<Note>.unmodifiable(_notesCache!), failure: null);
    }

    final result = await _source.fetchNotes(limit: limit, offset: offset);
    if (result.failure == null && offset == 0) {
      _notesCache = List<Note>.of(result.notes);
      _cachedLimit = limit;
      _byIdCache
        ..clear()
        ..addEntries(
          result.notes
              .where((note) => note.id != null)
              .map((note) => MapEntry(note.id!, note)),
        );
    }
    return result;
  }

  @override
  Future<({Note? note, Failure? failure})> getNoteById(int id) async {
    final cached = _byIdCache[id];
    if (cached != null) {
      return (note: cached, failure: null);
    }

    final result = await _source.getNoteById(id);
    final note = result.note;
    if (result.failure == null && note?.id != null) {
      _byIdCache[note!.id!] = note;
    }
    return result;
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final result = await _source.addNote(title: title, body: body);
    invalidate();
    return result;
  }

  @override
  Future<({bool success, Failure? failure})> updateNote(Note note) async {
    final result = await _source.updateNote(note);
    invalidate();
    return result;
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    final result = await _source.deleteNote(id);
    invalidate();
    return result;
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    final cached = _dirtyCountCache;
    if (cached != null) {
      return (count: cached, failure: null);
    }

    final result = await _source.countDirty();
    if (result.failure == null) {
      _dirtyCountCache = result.count;
    }
    return result;
  }

  @override
  Future<({bool success, Failure? failure})> markAllSynced() async {
    final result = await _source.markAllSynced();
    invalidate();
    return result;
  }
}

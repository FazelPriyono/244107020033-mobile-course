import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  const AddNote(this._repository);
  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) {
    if (title.trim().isEmpty) {
      return Future.value((
        note: null,
        failure: const ValidationFailure('Judul catatan tidak boleh kosong'),
      ));
    }
    return _repository.addNote(title: title.trim(), body: body.trim());
  }
}

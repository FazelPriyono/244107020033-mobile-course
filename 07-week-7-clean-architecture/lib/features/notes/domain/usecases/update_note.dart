import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  const UpdateNote(this._repository);
  final NoteRepository _repository;

  Future<({bool success, Failure? failure})> call(Note note) {
    if (note.title.trim().isEmpty) {
      return Future.value((
        success: false,
        failure: const ValidationFailure('Judul catatan tidak boleh kosong'),
      ));
    }
    return _repository.updateNote(note);
  }
}

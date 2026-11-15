import '../../../../core/failures.dart';
import '../../../../core/validators.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  const UpdateNote(this._repository);
  final NoteRepository _repository;

  Future<({bool success, Failure? failure})> call(Note note) {
    if (!isValidNoteTitle(note.title)) {
      return Future.value((
        success: false,
        failure: const ValidationFailure('Judul catatan tidak boleh kosong'),
      ));
    }
    return _repository.updateNote(
      note.copyWith(title: note.title.trim(), body: note.body.trim()),
    );
  }
}

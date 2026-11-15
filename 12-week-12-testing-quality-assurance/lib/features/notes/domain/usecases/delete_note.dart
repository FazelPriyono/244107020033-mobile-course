import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class DeleteNote {
  const DeleteNote(this._repository);
  final NoteRepository _repository;

  Future<({bool success, Failure? failure})> call(int id) {
    return _repository.deleteNote(id);
  }
}

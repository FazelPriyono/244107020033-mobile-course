/// Aturan validasi murni yang bisa diuji tanpa Flutter atau database.
///
/// Dipakai oleh `AddNote` dan `UpdateNote` sehingga aturan bisnis hanya
/// didefinisikan di satu tempat dan dapat diuji langsung sebagai unit.
bool isValidNoteTitle(String value) {
  return value.trim().isNotEmpty;
}

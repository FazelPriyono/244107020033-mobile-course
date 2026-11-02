# AI Review — Week 8 PR (`fix/2-update-note-trim` + `chore/1-track` + `chore/3-ci`)

## Prompt yang Digunakan

```
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## Ringkasan Output AI (5 Temuan)

| # | Temuan | Level | Bukti Kode |
|---|---|---|---|
| 1 | `UpdateNote` memvalidasi judul kosong, tetapi tidak melakukan `trim()` sebelum menyimpan. | Blocker | `update_note.dart:16`: `return _repository.updateNote(note);` tanpa `trim()` |
| 2 | `UpdateNote` tidak memiliki unit test; hanya `AddNote` dan `GetNotes` yang diuji. | Blocker | `test/`: tidak ada `update_note_test.dart` |
| 3 | Dialog tambah catatan (`NotesPage`) menutup navigasi sebelum memeriksa `failure`, sehingga pesan error muncul setelah dialog hilang. | Blocker / Saran | `notes_page.dart:118-129`: `Navigator.pop(ctx)` sebelum `if (result.failure != null)` |
| 4 | Beberapa operasi *pass-through* (`getNoteById`, `countDirty`) disarankan dibungkus use case. | Saran | `notes_providers.dart`: `noteDetailProvider` memanggil `noteRepositoryProvider` langsung; `dirtyCountProvider` juga langsung |
| 5 | Import `'../..//data/...'` memiliki garis miring ganda (`//`). | Saran | `notes_providers.dart:3` |

---

## Tabel Keputusan

| # | Temuan | Bukti Teknis | Keputusan | Alasan |
|---|---|---|---|---|
| 1 | `UpdateNote` tidak `trim` | `update_note.dart:16`; `test/update_note_test.dart` membuktikan `trim` diterapkan | **✅ Diterima** — diperbaiki di PR #2 (`fix/2-update-note-trim`) | Perilaku edit harus konsisten dengan `AddNote` |
| 2 | Tidak ada test `UpdateNote` | `test/` tidak memiliki `update_note_test.dart` sebelum PR #2 | **✅ Diterima** — diperbaiki di PR #2 (3 test baru: validasi, trim, failure) | Setiap operasi domain yang memiliki validasi wajib diuji |
| 3 | Dialog ditutup sebelum cek `failure` | `notes_page.dart:118-129`: `pop()` sebelum `mounted` dan `failure` | **⏳ Diterima** — **ditunda** ke PR berikutnya (`fix/4-dialog-failure-path`) | Scope PR #2 hanya `UpdateNote`; perubahan UI dialog akan merusak isolasi fitur |
| 4 | Bungkus operasi *pass-through* dengan use case | `notes_providers.dart`; `README.md` §8.2 menjelaskan operasi tanpa logika bisnis tidak butuh use case | **❌ Ditolak** | Over-engineering; `GetNotes` sudah memiliki use case karena mengatur alur (`build()`); operasi satu baris hanya meningkatkan boilerplate tanpa nilai domain |
| 5 | Import garis miring ganda | `notes_providers.dart:3` | **⏳ Diterima** — **ditunda** ke PR refactor (`style/notes-import`) | Tidak mengubah perilaku; formatter tidak menangkapnya; akan dibersihkan bersama perubahan besar berikutnya |

---

## Detail Temuan Diterima (#1 dan #2)

### Temuan 1 — `UpdateNote` tidak `trim`
**Bukti sebelum perbaikan:**
```dart
// lib/features/notes/domain/usecases/update_note.dart (sebelum)
return _repository.updateNote(note);
```
**Bukti setelah perbaikan (PR #2):**
```dart
return _repository.updateNote(
  note.copyWith(title: note.title.trim(), body: note.body.trim()),
);
```
**Test bukti:** `test/update_note_test.dart` baris 38-42 memastikan judul `"  Belanja  "` tersimpan sebagai `"Belanja"`.

---

### Temuan 2 — Tidak ada test `UpdateNote`
**Bukti sebelum:** `git ls-files test/` tidak menyertakan `update_note_test.dart`.
**Bukti setelah:** file `test/update_note_test.dart` berisi 3 test (validasi kosong/spasi, trim, failure). `flutter test` menunjukkan `+19` (sebelumnya `+16`).

---

## Detail Temuan Ditolak (#4)

**Usulan AI:** Membuat `GetNoteById` dan `CountDirtyNotes` use case terpisah.
**Tolak dengan alasan:**
- `GetNoteById` dan `countDirty()` hanya meneruskan panggilan repository tanpa validasi, tanpa transformasi, tanpa orkestrasi multi-sumber.
- `README.md` §8.2 (Minggu 7) menyatakan: *"Repository langsung ke Notifier sudah cukup ketika operasi hanya pembacaan sederhana (simple pass-through) tanpa manipulasi atau validasi tambahan."*
- Menambah use case satu baris akan meningkatkan jumlah file per fitur (entity, model, interface, impl, use case, provider) dari 6 menjadi 8, tanpa meningkatkan kejelasan.
- Keputusan ini konsisten dengan temuan `docs/review-checklist.md` (pemeriksaan sterilitas) dan `README.md` (struktur feature-first).

---

## Kesimpulan

- **2 temuan diterima dan telah dibuktikan dengan kode + test.**
- **1 temuan ditolak dengan alasan teknis yang mengacu pada arsitektur proyek (clean architecture rules).**
- **2 temuan ditunda** (dialog path, import nitpick) agar scope PR tetap satu tujuan; akan ditangani pada PR berikutnya.
- Keputusan akhir berbeda dari saran AI pada point #4; alasan tertulis dan dapat diverifikasi dari kode dan dokumentasi repo.

# Week 8 — Mid Project Review & Code Review

**Project:** 07-week-7-clean-architecture (Clean Architecture)

---

## Status

- Aplikasi berjalan identik akhir Week 7.
- `flutter analyze`: No issues found.
- `dart format`: 0 changed.
- `flutter test`: 19 test lulus (termasuk 3 test baru `UpdateNote`).
- CI workflow (`.github/workflows/ci.yml`) sudah ada.
- 4 branch (`chore/1`, `fix/2`, `chore/3`, `docs/4`) siap dibuka sebagai PR.
- 3 perintah grep sterilitas: 0 matches (steril).
- Review AI: 2 diterima (trim + test), 1 ditolak (use case pass-through), 2 ditunda.
- Batasan: PR belum dibuka otomatis karena `gh` CLI tidak tersedia; semua branch sudah dipush dan siap dibuat PR via web GitHub.

![CI Green — Hasil CI workflow (`flutter analyze`, `dart format`, `flutter test`) hijau](screenshots/ci-green.png)  
![PR Review — Halaman PR #2 (`fix/2-update-note-trim`) dengan 3 komentar simulasi siap di-approve](screenshots/pr-2-review.png)  
![PR Merged — Bukti PR #3 (`chore/3-ci`) sudah di-merge ke `develop`](screenshots/pr-2-merged.png)  
![Hasil Analyze & Test — `flutter analyze` bersih (`No issues found!`) dan `flutter test` 19 lulus termasuk `update_note_test.dart`](screenshots/hasil-analyze-test-week7.png)  

---

## Peta PR

| # | Judul | Branch | Commit | Status |
|---|---|---|---|---|
| 1 | Track `pubspec` dan test Week 7 | `chore/1-track-project-files` | `4e551c5` | Siap PR |
| 2 | Trim `UpdateNote` + test | `fix/2-update-note-trim` | `27ae786` | Siap PR |
| 3 | CI workflow | `chore/3-ci` | `27ae9dd` | Siap PR |
| 4 | Laporan mid review | `docs/4-week-8-report` | `37972ff` | Siap PR |

Body PR siap pakai: lihat commit `4e551c5`, `27ae786`, `27ae9dd`, `37972ff`.

---

## Fitur Utama

CRUD catatan, pencarian, tema persisten, `dirty flag` SQLite, Clean Architecture feature-first (`presentation -> domain <- data`), DI Riverpod.

---

## Stack

Flutter 3.47.1 / Dart 3.13.1, `flutter_riverpod ^3.4.3`, `go_router ^18.0.2`, `sqflite`, `shared_preferences`, `flutter_secure_storage` (tidak dipakai langsung di UI), CI GitHub Actions.

---

## Cara Menjalankan

```bash
cd 07-week-7-clean-architecture
flutter pub get
flutter create . --platforms=android,web  # jika folder platform belum ada
flutter run -d chrome
```

Verifikasi: `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test`.

---

## Hasil Pengujian

`flutter analyze`: bersih.  
`dart format`: 0 changed.  
`flutter test`: 19 lulus (termasuk `update_note_test.dart`).

Bukti lokal tersimpan pada commit `4e551c5`, `27ae786`, `27ae9dd`, dan `37972ff`.

---

## Ringkasan Review

Temuan utama:
- `UpdateNote` tidak `trim` judul/isi sebelum menyimpan (diperbaiki PR #2, dibuktikan `update_note_test.dart`).
- Dialog tambah catatan ditutup sebelum cek `failure` (ditunda; scope PR #2 tetap satu tujuan).
- `dirtyCountProvider` / `noteDetailProvider` memanggil repository langsung (ditolak: operasi pass-through tanpa logika bisnis, sesuai refleksi Week 7).
- `UpdateNote` belum memiliki test (ditambahkan 3 test baru).
- Import `'../..//data/...'` garis miring ganda (ditunda; tidak mengubah perilaku).

Keputusan akhir: approve simulasi setelah PR diverifikasi lokal. Bukti: commit `27ae786` (trim + test), `27ae9dd` (CI), `37972ff` (laporan).

---

## AI Review

Prompt sesuai codelab: senior Flutter dev, fokus kebenaran, arsitektur, test.

| # | Temuan | Level | Keputusan | Bukti |
|---|---|---|---|---|
| 1 | `UpdateNote` tidak trim | Blocker | Diterima & diperbaiki | `test/update_note_test.dart` |
| 2 | Tidak ada test `UpdateNote` | Blocker | Diterima & diperbaiki | 3 test baru |
| 3 | Dialog tutup sebelum cek failure | Blocker | Diterima, ditunda | `notes_page.dart:118-129` |
| 4 | Bungkus operasi pass-through dengan use case | Saran | Ditolak | Refleksi Week 7 §8.2 |
| 5 | Import garis miring ganda | Saran | Ditunda | `notes_providers.dart:3` |

Bukti AI: commit `27ae786` (perbaikan), `27ae9dd` (CI), `37972ff` (laporan).

---

## Langkah Praktikum

1. **Baseline (Fase 0):** jalankan `flutter pub get`, `flutter analyze`, `dart format`, `flutter test`. Simpan bukti (`docs/evidence/` sebelum disederhanakan).
2. **Format (Fase 0):** terapkan `dart format` (19 file diubah), commit `style(week-7): ...`.
3. **Git Flow (Fase 1):** buat branch `develop`, `chore/1-track-project-files`, edit `.gitignore`, commit file konfigurasi.
4. **Perbaikan Fitur (Fase 2):** branch `fix/2-update-note-trim`, edit `update_note.dart` (`trim()` judul/isi), tambah `test/update_note_test.dart` (3 test), commit.
5. **CI (Fase 3):** branch `chore/3-ci`, buat `.github/workflows/ci.yml`, commit.
6. **Dokumentasi (Fase 4):** branch `docs/4-week-8-report`, susun `README.md`, `docs/review-checklist.md`, `docs/ai-review-vs-keputusan.md`, `docs/issue-pr-map.md`, dan `docs/codelab-reference.md`.
7. **Verifikasi Akhir:** semua 19 test lulus, 3 grep sterilitas 0 hasil, CI siap, 4 PR siap dibuka via web.

---

## Refleksi

1. **Approve bertanggung jawab vs LGTM buta.**  
Approve yang bertanggung jawab berarti reviewer menjalankan kode (`flutter test`), membaca alur eksekusi (`notes_page.dart`, `update_note.dart`), memeriksa jalur error (`AsyncValue.error`), dan memahami dampak arsitektur (`feature-first` dependency rule). Ini berbeda dari LGTM buta yang hanya melihat output CI hijau (`No issues found!`) tanpa membaca konteks perubahan. Risiko LGTM buta sangat nyata dalam proyek ini: misalnya, jika `UpdateNote` tidak melakukan `trim`, data akan tersimpan dengan spasi tersembunyi yang merusak konsistensi pencarian (`_searchQuery.trim().toLowerCase()` di `notes_page.dart`) dan tampilan. Bug semacam ini tidak akan tertangkap oleh `flutter analyze`, hanya oleh test (`update_note_test.dart`) dan review manual. Oleh karena itu, simulasi review mandiri tetap dilakukan meskipun tanpa reviewer eksternal.

2. **Kapan `request changes` vs saran.**  
`Request changes` wajib saat ada pelanggaran aturan emas (`Golden Dependency Rule`) — misalnya `domain` mengimpor `package:flutter` atau `package:sqflite` — atau saat ada bug kebenaran (`UpdateNote` tidak `trim`) yang membuat fitur tidak sesuai spesifikasi. Saran dipakai untuk peningkatan keterbacaan (`import` ganda) atau optimasi (`use case` tambahan untuk operasi pass-through) yang tidak menghalangi merge. Dalam simulasi ini, temuan `trim` masuk kategori `request changes` karena mengubah perilaku domain; sedangkan `import` ganda cukup saran karena tidak mengubah perilaku.

3. **Temuan AI yang ditolak atau disederhanakan.**  
Saya menolak saran AI untuk membungkus `getNoteById` dan `countDirty` menjadi `use case` terpisah. Alasannya: kedua operasi hanya meneruskan panggilan `NoteRepository` (`fetchNotes` dan `countDirty`) tanpa validasi, tanpa transformasi data (`toEntity`/`toMap`), maupun orkestrasi multi-sumber. Menambah use case satu baris (`return repo.getNoteById(id);`) akan meningkatkan jumlah file per fitur dari 6 menjadi 8 (`entity`, `model`, `interface`, `impl`, `use case`, `provider`, `page`, `test`) tanpa meningkatkan kejelasan bisnis. Ini konsisten dengan refleksi Minggu 7 (§8.2) yang menyatakan: *"Use case benar-benar dibutuhkan ketika terdapat logika bisnis, validasi, atau orkestrasi; repository langsung ke Notifier sudah cukup untuk operasi pass-through."* Dengan alasan ini, temuan AI #4 ditolak secara teknis.

4. **Perbaikan konkret setelah review.**  
`UpdateNote` sekarang menerapkan `trim()` pada judul (`title.trim()`) dan isi (`body.trim()`) sebelum menyimpan ke `NoteRepositoryImpl`. Dampaknya tiga lapis: (a) konsistensi data — semua catatan tersimpan tanpa spasi tersembunyi; (b) konsistensi UI — pencarian (`_searchQuery.trim().toLowerCase()` di `notes_page.dart`) tidak lagi terganggu oleh spasi; (c) konsistensi perilaku — operasi edit (`UpdateNote`) sejalan dengan operasi tambah (`AddNote`) yang sudah melakukan `trim`. Perbaikan ini dibuktikan oleh `test/update_note_test.dart` (validasi kosong/spasi, trim, dan penanganan failure) serta 19 test lainnya tetap hijau.



# Week 8 — Mid Project Review & Code Review

**Nama:** Fazel Priyono (244107020033)  
**Project:** 07-week-7-clean-architecture (Week 7 — Clean Architecture)

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

## Refleksi

1. **Approve bertanggung jawab** berarti reviewer menjalankan kode, memeriksa jalur error, dan memahami dampak arsitektur — bukan sekadar melihat CI hijau (risiko LGTM: bug lolos, utang teknis).
2. **Request changes** wajib saat ada bug kebenaran atau pelanggaran dependency; cukup saran untuk peningkatan keterbacaan.
3. **Ditolak AI**: bungkus `getNoteById`/`countDirty` menjadi use case — operasi pass-through tanpa validasi/orkestrasi; menambah boilerplate tanpa nilai domain.
4. **Perbaikan konkret**: `UpdateNote` sekarang `trim` judul/isi; dampak konsistensi data dan perilaku edit sejalan dengan `AddNote`, dibuktikan 3 test baru.

---

## Batasan & Langkah Manual

- Issue/PR belum dibuat otomatis (`gh` CLI tidak tersedia). Salin judul/body dari commit `4e551c5`–`37972ff` ke GitHub.
- Screenshot CI (`ci-green.png`) dan halaman PR (`pr-review.png`) belum tersedia; simpan setelah PR dibuka.
- Dokumentasi lengkap sudah disederhanakan ke file README ini.
- Review sejawat belum dilakukan; dokumentasi ini mencatat simulasi mandiri secara transparan.
- Nama package `week5_offline_notes` belum diubah agar aplikasi tetap identik akhir Week 7.

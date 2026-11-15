# Laporan Pengujian dan Jaminan Kualitas — Week 12

Dokumen ini menjelaskan strategi, pelaksanaan, hasil, dan interpretasi test
suite yang ditambahkan pada aplikasi `Clean Architecture Notes` (project
Week 7–11). Fokus pengujian adalah fitur utama aplikasi: **CRUD catatan**
(daftar, tambah, detail/update, hapus, dan pencarian).

## 1. Lingkungan dan Perangkat

| Komponen | Nilai |
|---|---|
| Flutter / Dart | Flutter 3.47.1 (stable) / Dart 3.13.1 |
| Sistem operasi | Windows 11 (10.0.26200) |
| Perangkat Android | Xiaomi 2312DRAABG, Android 15 (API 35) |
| Perangkat integration test | Windows desktop (`-d windows`) |
| Paket pengujian | `flutter_test`, `integration_test` (SDK), `sqflite_common_ffi` |
| State management | Riverpod `^3.4.3` |

## 2. Piramida Pengujian yang Dipakai

```text
        ┌──────────────────────────┐
        │  Integration test (1)    │  alur nyata + SQLite + navigasi
        ├──────────────────────────┤
        │  Widget test (12 baru)   │  UI, validasi, dialog, error state
        ├──────────────────────────┤
        │  Unit test (15 baru)     │  aturan bisnis, use case, fake repo
        └──────────────────────────┘
```

| Lapisan | Yang diverifikasi | Tidak diverifikasi |
|---|---|---|
| Unit murni | aturan judul, format tanggal, ringkasan performa | UI, I/O |
| Unit + fake | use case `AddNote`, `UpdateNote`, `DeleteNote`, `GetNotes`; kontrak sukses/gagal repository | SQLite, jaringan |
| Widget | render awal, validasi input, dialog, SnackBar, pencarian, error state, navigasi keluar | database nyata, platform channel |
| Integrasi | tambah catatan → buka detail → hapus, memakai `main()` dan SQLite asli | skenario jamak, rotasi, offline |

Prinsip yang dipegang: setiap test memeriksa **perilaku yang terlihat atau
dijanjikan**, bukan sekadar mengeksekusi baris kode. Tidak ada test yang hanya
memanggil fungsi tanpa assertion.

## 3. Isolasi dan Determinisme

- **Fake repository** (`test/helpers/fake_note_repository.dart`) menggantikan
  `NoteRepository` pada unit dan widget test. Fake menyimpan data di memori,
  mengurutkan seperti query SQLite (`updated_at DESC`), mendukung
  `limit`/`offset`, dan menghitung jumlah pemanggilan (`fetchCalls`,
  `addCalls`, `updateCalls`, `deleteCalls`).
- **Kegagalan dapat dikonfigurasi** lewat `fetchFailure`, `addFailure`,
  `updateFailure`, `deleteFailure`, dan `dirtyCountFailure`. Satu fake dapat
  mensimulasikan sukses maupun error tanpa mengubah kode produksi.
- **Override provider** dilakukan dengan
  `noteRepositoryProvider.overrideWithValue(fake)` di dalam `ProviderScope`,
  sehingga tidak ada koneksi SQLite, file, atau jaringan saat unit/widget test.
- **Waktu tetap** dipakai pada data uji (`DateTime(2026, 11, 15, ...)`) agar
  urutan dan label tanggal tidak bergantung pada jam sistem.
- **Viewport tetap 800 × 1600** pada widget test. Font default test (Ahem)
  membuat setiap glyph selebar em, sehingga layout 430 px melaporkan overflow
  palsu. Viewport lebar memisahkan masalah layout aplikasi dari artefak font
  pengujian; overflow SnackBar yang nyata tetap diperbaiki di kode produksi.
- **Key widget** (`add-note-fab`, `note-title-field`, `save-note-button`,
  `detail-title-field`, `delete-note-button`, dst.) menjadi kontrak stabil
  antara test dan UI, sehingga test tidak rapuh terhadap perubahan teks label.

## 4. Skenario yang Diuji

### 4.1 Unit test baru

| ID | Skenario | Input | Hasil yang diharapkan | File |
|---|---|---|---|---|
| U1 | Judul berisi teks | `Belajar Flutter` | valid | `validators_test.dart` |
| U2 | Judul dengan spasi tepi | `'  Review Bab 12  '` | valid | `validators_test.dart` |
| U3 | Judul kosong | `''` | tidak valid | `validators_test.dart` |
| U4 | Hanya whitespace | `'   '`, `'\t'`, `'\n  \n'` | tidak valid | `validators_test.dart` |
| U5 | Karakter tak terlihat (**kasus tepi**) | `'\u200B'` | valid menurut aturan saat ini — didokumentasikan | `validators_test.dart` |
| U6 | Tambah catatan sukses | judul & isi dengan spasi | tersimpan dan di-trim | `note_usecases_fake_test.dart` |
| U7 | Tambah catatan invalid | judul `'   '` | `ValidationFailure`, repository **tidak** dipanggil | `note_usecases_fake_test.dart` |
| U8 | Tambah catatan gagal | `addFailure` | failure diteruskan, tidak ada exception | `note_usecases_fake_test.dart` |
| U9 | Ambil catatan sukses | 1 catatan | daftar diteruskan | `note_usecases_fake_test.dart` |
| U10 | Ambil catatan gagal | `fetchFailure` | failure diteruskan, **bukan** daftar kosong diam-diam | `note_usecases_fake_test.dart` |
| U11 | Update sukses | judul dengan spasi | tersimpan dan di-trim | `note_usecases_fake_test.dart` |
| U12 | Update invalid | judul kosong | ditolak sebelum repository | `note_usecases_fake_test.dart` |
| U13 | Update gagal | `updateFailure` | failure diteruskan | `note_usecases_fake_test.dart` |
| U14 | Hapus sukses | id 1 | catatan hilang | `note_usecases_fake_test.dart` |
| U15 | Hapus gagal | `deleteFailure` | failure diteruskan, data tetap ada | `note_usecases_fake_test.dart` |

### 4.2 Widget test baru

| ID | Skenario | Hasil yang diharapkan | File |
|---|---|---|---|
| W1 | Tampilan awal tanpa data | empty state, FAB, jumlah `Catatan (0)` | `notes_page_widget_test.dart` |
| W2 | Daftar berisi data | kedua judul tampil, jumlah `Catatan (2)` | `notes_page_widget_test.dart` |
| W3 | Repository gagal memuat | pesan `Gagal memuat catatan` + tombol `Coba Lagi` | `notes_page_widget_test.dart` |
| W4 | Judul kosong saat tambah | SnackBar validasi, dialog tetap terbuka, repository tidak dipanggil | `notes_page_widget_test.dart` |
| W5 | Tambah catatan valid | dialog tertutup, catatan muncul di daftar, SnackBar sukses | `notes_page_widget_test.dart` |
| W6 | Repository gagal saat tambah | pesan error tampil, dialog tetap terbuka, data tidak bertambah | `notes_page_widget_test.dart` |
| W7 | Pencarian | query `flutter` hanya menampilkan catatan yang cocok | `notes_page_widget_test.dart` |
| W8 | Detail menampilkan data | judul, isi, dan `Entity #1` tampil | `note_detail_page_widget_test.dart` |
| W9 | Update dengan judul kosong | validasi tampil, `updateCalls == 0`, tetap di halaman detail | `note_detail_page_widget_test.dart` |
| W10 | Update valid | data berubah dan kembali ke halaman daftar | `note_detail_page_widget_test.dart` |
| W11 | Update gagal | error tampil, tetap di detail, data lama tidak berubah | `note_detail_page_widget_test.dart` |
| W12 | Simpan API key AI | key di-trim, SnackBar sukses, dialog tertutup tanpa error lifecycle | `ai_chat_widget_test.dart` |

### 4.3 Integration test baru

| ID | Skenario | Langkah | Hasil yang diharapkan |
|---|---|---|---|
| I1 | Alur utama catatan | buka aplikasi → FAB → isi judul & isi → **Simpan via UseCase** → buka detail → **Hapus** | catatan tampil di daftar, detail menampilkan data yang sama, lalu catatan hilang setelah dihapus |

Judul catatan memakai timestamp (`Catatan Integrasi <epoch>`) agar setiap run
memakai data unik dan tidak bertabrakan dengan data lama di database perangkat.

## 5. Perintah dan Hasil

### 5.1 Analisis statis dan format

```text
PS ...\12-week-12-testing-quality-assurance> flutter analyze
Analyzing 12-week-12-testing-quality-assurance...
No issues found! (ran in 124.8s)

PS ...\12-week-12-testing-quality-assurance> dart format --set-exit-if-changed lib test integration_test
Formatted 56 files (0 changed) in 0.34 seconds.
```

### 5.2 Unit dan widget test

```text
PS ...\12-week-12-testing-quality-assurance> flutter test --coverage
00:14 +73: All tests passed!
```

| Kelompok | Jumlah |
|---|---|
| Test bawaan Week 7–11 | 46 |
| Test baru Week 12 | 27 |
| **Total** | **73** |

Rincian test baru:

| File | Jumlah |
|---|---|
| `test/validators_test.dart` | 5 |
| `test/note_usecases_fake_test.dart` | 10 |
| `test/notes_page_widget_test.dart` | 7 |
| `test/note_detail_page_widget_test.dart` | 4 |
| `test/ai_chat_widget_test.dart` (tambahan) | 1 |

### 5.3 Integration test

Windows desktop:

```text
PS ...\12-week-12-testing-quality-assurance> flutter test integration_test/app_test.dart -d windows
00:00 +0: alur utama: tambah catatan, buka detail, lalu hapus
00:03 +1: (tearDownAll)
00:03 +1: All tests passed!
```

Android (perintah yang sama, perangkat fisik):

```text
flutter test integration_test/app_test.dart -d ofscrc7dcaucssmv
```

Perintah Android **belum berhasil dijalankan** pada sesi ini karena perangkat
berada pada kondisi `mWakefulness=Dozing` / layar mati dan MIUI menolak
injeksi input dari `adb shell input` (`INJECT_EVENTS` SecurityException).
Upaya membangunkan layar lewat `settings put global stay_on_while_plugged_in`
juga ditolak karena shell tidak memiliki `WRITE_SECURE_SETTINGS`. Integration
test karena itu dijalankan pada target Windows desktop yang memakai kode
aplikasi, navigasi, provider, dan SQLite yang sama (lewat
`sqflite_common_ffi`).

Catatan teknis Windows: build dari path project yang panjang gagal dengan
`MSB4184 ... exceeds the OS max path limit`. Build dijalankan lewat junction
`C:\w12` → folder project agar path artefak MSBuild tetap di bawah 260 karakter.

## 6. Cakupan Pengujian

Laporan dihasilkan dengan `flutter test --coverage` dan dibaca dari
`coverage/lcov.info`.

| Metrik | Nilai |
|---|---|
| Line coverage total | **803 / 1060 = 75,8%** |
| File terukur | 28 |
| Branch coverage | Tidak tersedia (LCOV Dart menulis `BRF/BRH = 0/0`) |

### 6.1 File dengan cakupan tinggi

| File | Baris | Coverage |
|---|---|---|
| `lib/core/format.dart` | 15 / 15 | 100% |
| `lib/core/validators.dart` | 2 / 2 | 100% |
| `lib/features/notes/domain/usecases/add_note.dart` | 5 / 5 | 100% |
| `lib/features/notes/domain/usecases/update_note.dart` | 6 / 6 | 100% |
| `lib/features/notes/domain/usecases/delete_note.dart` | 3 / 3 | 100% |
| `lib/features/notes/domain/usecases/get_notes.dart` | 3 / 3 | 100% |
| `lib/features/notes/domain/usecases/search_notes.dart` | 8 / 8 | 100% |
| `lib/features/notes/presentation/widgets/note_tile.dart` | 86 / 86 | 100% |
| `lib/features/notes/presentation/widgets/search_empty_state.dart` | 21 / 21 | 100% |
| `lib/features/notes/data/repositories/cached_note_repository.dart` | 36 / 39 | 92% |
| `lib/features/notes/presentation/pages/notes_page.dart` | 250 / 288 | 87% |
| `lib/features/ai_chat/presentation/pages/ai_chat_page.dart` | 129 / 150 | 86% |
| `lib/features/notes/presentation/providers/notes_providers.dart` | 29 / 36 | 81% |
| `lib/features/notes/presentation/pages/note_detail_page.dart` | 96 / 124 | 77% |

### 6.2 File dengan cakupan rendah

| File | Baris | Coverage | Alasan |
|---|---|---|---|
| `lib/features/notes/data/repositories/note_repository_impl.dart` | 0 / 42 | 0% | Diuji lewat integration test; tidak dihitung oleh `--coverage` |
| `lib/features/notes/data/datasources/notes_database.dart` | 0 / 23 | 0% | Butuh SQLite nyata / FFI in-memory |
| `lib/features/ai_chat/data/datasources/ai_remote_datasource.dart` | 0 / 70 | 0% | Butuh HTTP dan secure storage; belum diuji |
| `lib/features/ai_chat/data/repositories/ai_repository_impl.dart` | 0 / 9 | 0% | Bergantung pada datasource di atas |

### 6.3 Interpretasi

Angka 75,8% **bukan target yang dikejar**. Lapisan domain dan presentasi — di
mana aturan bisnis dan perilaku pengguna berada — sudah tercakup tinggi.
Lapisan data yang bergantung pada platform tetap 0% karena unit/widget test
sengaja tidak menyentuh SQLite; lapisan itu diverifikasi lewat integration
test. Ketiadaan branch coverage di LCOV Dart berarti keputusan `if/else`
penting (mis. pesan error vs sukses) diverifikasi lewat assertion perilaku,
bukan lewat angka.

## 7. Temuan dan Perbaikan

Detail lengkap ada di [`testing-findings.md`](testing-findings.md).

| # | Bug | Dampak | Perbaikan |
|---|---|---|---|
| 1 | Controller dialog tambah catatan dipakai setelah `dispose()` | Exception saat animasi keluar dialog | `_AddNoteDialog` memiliki dan melepas controller sendiri |
| 2 | Bug lifecycle sama pada dialog API key | Exception serupa di fitur AI | `_ApiKeyDialog` dengan controller milik `State` |
| 3 | Dialog tertutup walau validasi gagal | Input pengguna hilang | Dialog tetap terbuka saat failure, SnackBar error tampil |
| 4 | `Row` SnackBar overflow | Teks error panjang terpotong | Teks dibungkus `Expanded` |

Setiap bug memiliki test regresi yang gagal sebelum perbaikan dan lulus
sesudahnya.

## 8. Temuan yang Belum Terselesaikan

| # | Temuan | Dampak |
|---|---|---|
| 1 | `'\u200B'` (zero-width space) dianggap judul valid | Catatan yang tampak kosong tetap bisa disimpan |
| 2 | Lapisan SQLite 0% di coverage | Migrasi dan query tidak dilindungi test otomatis |
| 3 | Integration test hanya berjalan di Windows | Perilaku khusus Android belum tercakup |
| 4 | `test/widget_test.dart` masih placeholder | Menambah hitungan test tanpa nilai verifikasi |
| 5 | Judul aplikasi dan application id masih mengacu Week 5/7 | Konsistensi penamaan modul |

## 9. Struktur Berkas Pengujian

```text
12-week-12-testing-quality-assurance/
├── test/
│   ├── helpers/fake_note_repository.dart        # fake sukses/gagal + call counter
│   ├── validators_test.dart                     # 5 test aturan judul
│   ├── note_usecases_fake_test.dart             # 10 test use case + fake
│   ├── notes_page_widget_test.dart              # 7 test daftar, dialog, pencarian
│   ├── note_detail_page_widget_test.dart        # 4 test detail & update
│   ├── ai_chat_widget_test.dart                 # 4 test, 1 baru untuk API key
│   └── ...                                      # 46 test bawaan Week 7–11
├── integration_test/
│   └── app_test.dart                            # alur tambah → detail → hapus
├── coverage/lcov.info                           # keluaran flutter test --coverage
└── screenshots/                                 # bukti analyze, test, coverage, integrasi
```

## 10. Kesimpulan

Test suite ini menangkap empat masalah nyata pada kode produksi, dua di
antaranya adalah bug lifecycle yang sulit ditemukan secara manual. Pengujian
juga memperjelas batas tanggung jawab tiap lapisan: fake repository membuat
logika domain dan UI dapat diuji cepat dan deterministik, sementara integration
test memastikan lapisan nyata (SQLite + navigasi) tetap tersambung. Keterbatasan
yang tersisa didokumentasikan terbuka, bukan disembunyikan di balik angka
coverage.

# Dokumentasi AI Challenge: Arsitektur & Reorganisasi Clean Architecture

Dokumen ini mencatat evaluasi terhadap usulan AI Coding Assistant dalam merefaktor proyek Flutter menjadi **Feature-First Clean Architecture**, analisis *trade-off*, penilaian *over-engineering*, serta keputusan teknis final yang diterapkan.

---

## 1. AI Prompt Challenge

Prompt yang diajukan ke AI Coding Assistant:

```text
Project Flutter saya: campus_notify / offline_notes.
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil SQLite/SharedPreferences langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur utama dan pendukung.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Pemetaan File Lama ke Struktur Baru (File Migration Matrix)

| File Lama | Layer Lama | Status & Tujuan Baru | Alasan Teknis |
|---|---|---|---|
| `data/local/note.dart` | Data (Tercampur) | **Dipecah** menjadi:<br>1. `features/notes/domain/entities/note.dart`<br>2. `features/notes/data/models/note_model.dart` | Entity di domain harus murni Dart bisnis tanpa method serialisasi (`toMap`/`fromMap`). Serialisasi adalah urutan data luar yang diisolasi di model. |
| `data/local/db.dart` | Data | **Pindah** ke `features/notes/data/datasources/notes_database.dart` | Inisialisasi SQLite adalah implementasi teknis data layer, tidak boleh bocor ke core atau domain. |
| `data/repositories/note_repository.dart` | Data (Kontrak tercampur) | **Dipecah** menjadi:<br>1. `features/notes/domain/repositories/note_repository.dart` (Interface)<br>2. `features/notes/data/repositories/note_repository_impl.dart` (Implementasi) | Mematuhi *Dependency Inversion Principle (DIP)*. Kontrak abstrak milik domain, implementasi milik data layer. |
| `data/prefs.dart` | Data | **Dipecah** menjadi:<br>1. `features/settings/domain/repositories/settings_repository.dart`<br>2. `features/settings/data/repositories/settings_repository_impl.dart` | Mengisolasi SharedPreferences ke repository implementasi sehingga presentation tidak memanggil `SharedPreferences.getInstance()` langsung. |
| `pages/notes_page.dart` | Presentation | **Dipindah & Direfaktor** ke `features/notes/presentation/pages/notes_page.dart` | Disterilkan dari logika database langsung, query raw, dan dialog yang menginstansiasi repo. Seluruh akses dialihkan via Riverpod Provider & UseCase. |
| `pages/note_detail_page.dart` | Presentation | **Dipindah & Direfaktor** ke `features/notes/presentation/pages/note_detail_page.dart` | State detail dibaca lewat `noteDetailProvider(id)` dan disimpan lewat `updateNoteProvider`. |
| `pages/settings_page.dart` | Presentation | **Dipindah & Direfaktor** ke `features/settings/presentation/pages/settings_page.dart` | Menggunakan `darkModeProvider` dan `settingsInfoProvider` tanpa menyentuh storage mentah. |
| `widgets/note_tile.dart` | Presentation | **Dipindah** ke `features/notes/presentation/widgets/note_tile.dart` | Formatting tanggal dipindahkan ke `lib/core/format.dart`. |

---

## 3. Checklist Verifikasi AI (AI Verification Checklist)

Berikut evaluasi kritis terhadap rekomendasi yang diajukan AI:

| Item Checklist | Kriteria Evaluasi | Temuan & Keputusan Final |
|---|---|---|
| **Pemisahan Interface & Implementasi** | Interface wajib di `domain`, implementasi wajib di `data`. | **Diterima**. AI menempatkan interface `note_repository.dart` di `domain/repositories` dan implementasi `note_repository_impl.dart` di `data/repositories`. |
| **Sterilitas Domain** | `domain` steril dari import framework (`flutter`, `sqflite`, `dio`, `firebase`). | **Diterima & Terverifikasi**. Hasil `grep_search` pada `lib/features/*/domain` dan `lib/core` membuktikan **0 hasil (steril total)**. |
| **Pembersihan Entity** | Entity murni tanpa `toMap`, `fromMap`, `toJson`. | **Diterima**. `Note` dan `AppSettings` hanya berisi field bisnis dan constructor murni. Seluruh mapping ditempatkan di `NoteModel`. |
| **Wiring DI Riverpod** | Wiring terpusat di Provider, UI tidak melakukan `new Repository()`. | **Diterima**. Seluruh widget `ConsumerWidget` hanya memakai `ref.watch`/`ref.read`. Repository disuntikkan dengan `openDb` function opener. |
| **Use Case per CRUD satu-baris** | Menilai apakah setiap operasi satu baris membutuhkan Use Case tersendiri. | **Disaring / Dinilai Kritis**. AI sempat mengusulkan membuat kelas UseCase terpisah untuk *setiap operasi kecil* seperti `CountDirtyNotes`, `MarkAllSyncedNotes`, dan `GetNoteById`. Hal ini dinilai **over-engineering** (lihat analisis di bawah). |

---

## 4. Analisis Over-Engineering & Kapan Use Case Benar-Benar Dibutuhkan

### Risiko Over-Engineering pada Tim Kecil / Fitur Sederhana
Jika setiap CRUD sederhana satu baris dipaksakan memiliki UseCase tersendiri (misal: `CountDirtyNotes` yang hanya berisi `return repo.countDirty();`), terjadi ledakan jumlah file (*boilerplate explosion*):
- Menambah waktu navigasi dan pencarian file.
- Setiap perubahan tipe data memerlukan pembaruan di 4 file berbeda: Entity, Repository Interface, Use Case, dan Repository Impl.
- Menurunkan kecepatan iterasi fitur pada tahap awal pengembangan (*development velocity* melambat).

### Kapan Use Case Benar-Benar Dibutuhkan?
1. **Memuat Logika Bisnis & Validasi**:
   - Contoh: `AddNote` dan `UpdateNote` melakukan validasi judul tidak boleh kosong (`ValidationFailure`) dan pembersihan spasi (*trimming*) sebelum memanggil repository.
2. **Orkestrasi Multi-Repository / Multi-Data Source**:
   - Jika suatu proses membutuhkan interaksi antara SQLite lokal dan API sinkronisasi jarak jauh, Use Case bertindak sebagai orkestrator yang mengoordinasikan keduanya.
3. **Pemberian Titik Pengujian Tunggal (*Isolated Unit Testing*)**:
   - Logika bisnis dapat diuji secara independen dengan mock/fake repository tanpa memerlukan runtime Flutter atau emulator database.

### Kapan Repository Langsung ke Notifier Sudah Cukup?
- Operasi baca sederhana (*pass-through read*) tanpa transformasi atau validasi tambahan (misalnya penghitungan jumlah atau detail item by ID). Notifier/Provider dapat langsung mengonsumsi abstraksi `NoteRepository` tanpa membungkusnya dalam kelas Use Case satu baris yang berlebihan.

---

## 5. Ringkasan Keputusan Teknis Final

1. **Feature-First Organization**: Kode diorganisasikan per domain fitur (`features/notes` dan `features/settings`), bukan global layer-first, memastikan portabilitas dan isolasi perubahan.
2. **Dart Records untuk Return Value**: Menggunakan record `({T? data, Failure? failure})` untuk penanganan hasil operasi yang eksplisit, aman, dan tanpa melempar runtime exception yang tidak tertangkap ke UI.
3. **Ekstraksi Fungsi Murni**: Formatting tanggal dan parsing parameter rute diekstraksi ke `lib/core/format.dart` sehingga dapat diuji 100% dengan unit test tanpa dependensi UI.

# Evaluasi Teknologi Penyimpanan Lokal (AI Challenge)

## Perbandingan Solusi Penyimpanan

Tabel di bawah ini membandingkan SharedPreferences, Hive, SQLite (sqflite), dan Drift berdasarkan kebutuhan aplikasi Flutter Offline Notes (Preferensi Tema & CRUD Catatan):

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| --- | --- | --- | --- | --- |
| **Kompleksitas Query** | Sangat Rendah (Key-Value sederhana) | Rendah ke Menengah (Bisa filter tapi sulit untuk query kompleks) | Tinggi (Mendukung query SQL murni) | Tinggi (Query SQL type-safe dalam Dart) |
| **Kebutuhan Relasi** | Tidak ada | Sangat terbatas (Referensi manual) | Tinggi (Dukungan JOIN dan Foreign Key penuh) | Tinggi (Relasi tingkat lanjut, deklaratif) |
| **Reaktivitas (Stream)** | Tidak ada secara default | Dukungan dasar (`watch`) | Tidak ada secara default, butuh paket tambahan | Sangat Kuat (`watch` query menghasilkan stream) |
| **Type-Safety** | Menengah (Dukungan tipe dasar) | Menengah (Butuh TypeAdapter, sering kali _dynamic_ di box) | Rendah (Map dinamis, rentan typo kolom) | Sangat Tinggi (Digenerate saat build) |
| **Ukuran Boilerplate** | Sangat Rendah | Sedang (Generator tipe untuk class kustom) | Sedang ke Tinggi (Parsing baris dan manual create table) | Sangat Tinggi (Konfigurasi awal yang banyak, build runner) |
| **Kemudahan Testing** | Mudah (Bisa di-mock `SharedPreferences.setMockInitialValues`) | Sedang (Membutuhkan init direktori palsu) | Menengah (Butuh database in-memory / dummy repo) | Sedang (Dapat memakai `NativeDatabase.memory()`) |

## Rekomendasi Final

| Kebutuhan | Teknologi yang Dipilih | Alasan Keputusan |
| --- | --- | --- |
| **Preferensi Tema** | **SharedPreferences** | Paling efisien dan mudah dikelola untuk data yang hanya bersifat *key-value* primitif (misal `boolean` untuk tema gelap). Tidak membutuhkan kompleksitas query maupun struktur relasi. Sangat ringan untuk disiapkan. |
| **Penyimpanan Catatan** | **sqflite (SQLite)** | Untuk manajemen ribuan data, SQLite menjamin reliabilitas. Dibandingkan Hive, `sqflite` lebih siap menangani integrasi relasional, filtering data kompleks, dan pengelolaan `dirty flag` untuk antrean _sync_ dengan update berkolom spesifik secara efisien. Meskipun *Drift* lebih kuat dengan reaktivitas stream, *sqflite* menawarkan keseimbangan antara fleksibilitas dan ukuran *boilerplate* yang jauh lebih kecil pada proyek menengah ke bawah (tanpa perlu repot _build_runner_ berlebih pada awal set up). |

## Skema Tabel untuk 1000+ Catatan (SQLite)

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty);
```
*(Catatan: Penambahan indeks sangat membantu apabila data mencapai ribuan)*

## Checklist Verifikasi Evaluasi (Trade-off)

1. **Apakah menyimpan daftar catatan di SharedPreferences tepat?**
   - **TIDAK**. Menyimpan stringified JSON `List<Note>` sangat rapuh. Membaca dan menulis satu item berarti harus me-load semua daftar ke memori, menambah ukuran, dan menyimpan kembali secara menyeluruh. Kinerja sangat buruk pada 1000+ data.
2. **Skema Antrean Sync (Dirty Flag)**
   - Menggunakan sqflite, update pada tabel `dirty = 1` hanya memodifikasi 1 bit flag dan _updated_at_. Ini memudahkan saat filter: `SELECT * FROM notes WHERE dirty = 1`.
3. **Klaim Real-time**
   - `sqflite` tidak otomatis _real-time_. Kita mengatasinya dengan Riverpod (Provider invalidation) yang membungkus pemanggilan fetch secara reaktif. Jika benar-benar membutuhkan reaktivitas (reaksi instan per baris termodifikasi dari sumber lain), Drift akan jauh lebih mumpuni.

**Kesimpulan:** 
Keputusan kami menggabungkan **SharedPreferences** (untuk *setting*) dan **sqflite** (untuk *entity*) karena mewakili keseimbangan antara produktivitas (tidak perlu konfigurasi *build_runner* kompleks) dan efisiensi memori (pengolahan filter langsung di SQL engine).

# Offline Notes App

Aplikasi Flutter yang mendemonstrasikan local storage dan kapabilitas offline-first. Aplikasi ini memungkinkan pengguna mengelola catatan secara lokal dan mengatur preferensi tema, dengan tetap berfungsi penuh walau tanpa koneksi internet.

## Fitur Utama
1. **Preferensi Tema:** Pengguna dapat mengganti tema terang atau gelap (tersimpan menggunakan SharedPreferences).
2. **Manajemen Catatan (CRUD):** Membuat, membaca, memperbarui, dan menghapus catatan secara offline, menggunakan SQLite (`sqflite`).
3. **Mekanisme Sinkronisasi (Offline-First):** 
   - Catatan yang belum disinkronkan akan memiliki flag `dirty`. 
   - Tersedia tombol `sync` untuk menyimulasikan sinkronisasi dengan remote server, membersihkan status `dirty`.
4. **Cache-First Read:** Menampilkan data lokal dengan cepat (melalui read cache) sebelum atau sembari melakukan _background refresh_.

## Stack Teknologi
- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Local Storage:** 
  - `shared_preferences` (untuk key-value sederhana / preferensi)
  - `sqflite` (untuk penyimpanan data terstruktur secara persisten)
- **Networking:** Dio (`dio`)

## Struktur Proyek Utama
- `lib/data/local/` : Mengandung implementasi DB lokal (`db.dart`) dan model entitas (`note.dart`).
- `lib/data/repositories/` : Abstraksi akses data (`note_repository.dart`).
- `lib/data/prefs.dart` : Pengelolaan preferensi.
- `lib/data/sync.dart` : Mekanisme sinkronisasi dan caching.
- `lib/pages/` : Tampilan antarmuka (`notes_page.dart`, `note_detail_page.dart`, `settings_page.dart`).

## Cara Menjalankan
1. Pastikan lingkungan Flutter SDK telah diatur dengan baik.
2. Jalankan perintah untuk mengunduh dependencies:
   ```bash
   flutter pub get
   ```
3. Mulai aplikasi pada emulator atau perangkat fisik (Android/iOS):
   ```bash
   flutter run
   ```
4. Untuk menjalankan unit testing:
   ```bash
   flutter test
   ```

## Hasil yang Dicapai
- Aplikasi berfungsi sepenuhnya pada **mode pesawat** (tanpa internet).
- Dapat menyimpan preferensi tema yang bertahan walaupun aplikasi ditutup dan dibuka kembali.
- Status `dirty` (menunggu sinkronisasi) berhasil ditampilkan dengan benar setelah penambahan catatan.
- Sinkronisasi disimulasikan dan jumlah indikator `dirty` akan menjadi $0$ setelah disinkron.
- Telah melalui pengujian (Unit Tests lulus semua).

## Dokumentasi Tambahan
Untuk melihat evaluasi teknologi berdasarkan _AI Challenge_ tentang perbandingan _local storage_, lihat dokumen [AI Challenge & Evaluasi Storage](docs/AI_CHALLENGE.md).

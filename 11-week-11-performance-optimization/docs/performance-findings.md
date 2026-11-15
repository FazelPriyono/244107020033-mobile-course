# Temuan Profiling Performa — Week 11

Dokumen ini mencatat hasil identifikasi masalah performa pada aplikasi
`Clean Architecture Notes` (project Week 7–10) sebelum optimasi diterapkan.

## 1. Metode

1. Aplikasi dijalankan pada perangkat Android fisik (Xiaomi 2312DRAABG,
   Android 15 / API 35, 1080 × 2400, density 440) dengan mode **profile**:
   ```bash
   flutter run --profile -d ofscrc7dcaucssmv
   ```
   Build pengukuran memakai `--dart-define=BENCHMARK_MODE=true` agar aplikasi
   langsung membuka halaman benchmark.
2. Skenario difokuskan pada beban terberat aplikasi: **scroll cepat daftar
   panjang** (300 item) yang memaksa `ListView.builder` membangun item baru
   setiap frame. Skenario ini sebelumnya diuji manual (buka daftar, scroll,
   buka detail, kembali) di DevTools; untuk before/after dipakai harness
   terkontrol agar hasil dapat dibandingkan secara adil.
3. Frame diukur dengan `FrameTiming` (`buildDuration`, `rasterDuration`,
   `totalSpan`) melalui `WidgetsBinding.instance.addTimingsCallback(...)`.
   Ambang jank memakai budget 60 FPS = **16,67 ms**.
4. Metrik yang dicatat: jumlah frame, jumlah/ persentase frame jank,
   rata-rata/P95/worst frame time, serta rata-rata build & raster.

> Mode `--debug` tidak dipakai karena memiliki overhead besar dan tidak
> representatif untuk profiling.

## 2. Ringkasan Temuan

| # | Temuan | Bukti / Lokasi | Dampak |
|---|--------|----------------|--------|
| 1 | Seluruh `NotesPage` me-rebuild setiap ketikan pencarian | `notes_page.dart` menonton `notesProvider`, `filteredNotesProvider`, `searchQueryProvider`, dan `dirtyCountProvider` di level halaman | AppBar, TabBar, header card, dan tab Arsitektur ikut dibangun ulang padahal tidak berubah |
| 2 | `NoteTile` tidak diisolasi dari repaint tetangga | Tidak ada `RepaintBoundary` pada item `ListView.builder` | Paint satu item berpotensi memicu repaint area yang lebih luas |
| 3 | `TextEditingController` dialog tidak pernah di-dispose | `_showAddNoteDialog()` dan `_showApiKeyDialog()` membuat controller lokal tanpa `dispose()` | Potensi memory leak setiap dialog dibuka/ditutup |
| 4 | `fetchNotes()` mengambil seluruh baris tanpa batas dan tanpa cache | `note_repository_impl.dart` memakai `db.query('notes')` tanpa `limit/offset`; provider membuat repository baru tanpa cache | Query SQLite + konversi `NoteModel` berulang pada setiap refresh |
| 5 | API key AI dibaca ulang dari secure storage setiap pesan | `AiRemoteDatasource.getApiKey()` memanggil `FlutterSecureStorage.read` + `SharedPreferences` pada setiap `ask()` | Overhead platform channel dan latency sebelum request jaringan |
| 6 | `imageCache` tidak dibatasi | Tidak ada konfigurasi `PaintingBinding.instance.imageCache` | Risiko pertumbuhan memori saat banyak gambar ditampilkan |
| 7 | `filteredNotesProvider` selalu menyalin list | `notesAsync.whenData(...)` dipanggil walau query kosong | Alokasi list baru yang tidak perlu pada kondisi normal |

### Temuan tambahan saat verifikasi

- `ListView.builder` **sudah** menambahkan `RepaintBoundary` otomatis pada
  setiap item (`addRepaintBoundaries: true`). `RepaintBoundary` eksplisit di
  dalam `NoteTile` bersifat redundan untuk daftar ini, sehingga lapisan
  tambahan tidak boleh diharapkan memberi percepatan besar. Boundary tetap
  dipertahankan agar isolasi juga berlaku bila `NoteTile` dipakai di
  scrollable kustom atau `Column` biasa.
- Query `ORDER BY updated_at DESC` dan `WHERE dirty = 1` belum memiliki index,
  sehingga SQLite melakukan full scan + sort ketika jumlah catatan membesar.

## 3. Baseline Metrics

Screenshot: [`../screenshots/before-profile.png`](../screenshots/before-profile.png)

Perangkat: Xiaomi 2312DRAABG, mode `--profile`, 300 item, scroll 600 px/frame
selama 5 detik.

| Metrik | Baseline |
|---|---|
| Total frame terukur | 217 |
| Frame jank (> 16,67 ms) | 95 |
| Persentase jank | 43,8% |
| Rata-rata frame time | 20,10 ms |
| P95 frame time | 34,23 ms |
| Worst frame time | 212,66 ms |
| Rata-rata build | 13,30 ms |
| Rata-rata raster | 4,75 ms |

## 4. Kesimpulan Awal

Bottleneck utama berada di **UI thread** (build/layout): rata-rata build
13,30 ms sementara raster hanya 4,75 ms. Artinya jank disebabkan oleh pekerjaan
membangun widget, bukan oleh GPU. Optimasi diarahkan ke:

1. mempersempit cakupan rebuild (Riverpod `select` + `Consumer` scoped);
2. mengisolasi repaint per item dan mengekstrak widget menjadi `const`;
3. menambah cache data + pagination di repository dan index SQLite;
4. memperbaiki kebocoran controller dan membatasi `imageCache`;
5. menghilangkan pembacaan secure storage berulang.

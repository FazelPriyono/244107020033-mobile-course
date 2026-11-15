# Laporan Optimasi Performa — Week 11

**Aplikasi:** `Clean Architecture Notes` (project Week 7–10)
**Perangkat uji:** Xiaomi 2312DRAABG (Android 15 / API 35), 1080 × 2400, density 440
**Mode:** `--profile` (bukan debug/release), renderer Impeller (Vulkan)
**Tanggal:** 15 November 2026

---

## 1. Ringkasan Eksekutif

Optimasi difokuskan pada beban yang paling sering membuat UI tersendat pada
aplikasi ini: **scroll daftar catatan** dan **rebuild saat pencarian**.

Enam teknik optimasi diterapkan (modul mensyaratkan minimal 3):

1. `const` constructor + ekstraksi widget (`NoteTile`).
2. `RepaintBoundary` untuk isolasi paint per item/chat bubble.
3. Riverpod `select` + `Consumer` scoped pada `NotesPage`.
4. Cache-first repository + pagination `limit/offset` + index SQLite.
5. Perbaikan kebocoran `TextEditingController` + pembatasan `imageCache`.
6. Cache API key AI di memori (menghapus platform channel berulang).

Hasil pada skenario scroll terkontrol: **rata-rata frame time turun 8,9%**
(20,10 → 18,31 ms), **P95 turun 12,3%** (34,23 → 30,03 ms), dan **worst frame
turun 53,6%** (212,66 → 98,62 ms). Persentase jank hanya turun tipis
(43,8% → 42,2%) karena skenario benchmark sengaja dibuat ekstrem
(600 px per frame), sehingga hampir setiap frame memang harus membangun
beberapa tile baru.

---

## 2. Metodologi Pengukuran

### 2.1 Alur

```text
flutter run --profile --dart-define=BENCHMARK_MODE=true
        │
        ▼
Halaman Benchmark Performa (/performance)
  ├── generate 300 Note
  ├── render ListView.builder + NoteTile asli
  ├── scroll cepat 600 px / frame selama 5 detik
  └── rekam FrameTiming (build, raster, totalSpan)
        │
        ▼
Ringkasan: total frame, jank, %, avg/P95/worst, avg build, avg raster
```

`FrameTiming` direkam global melalui
`WidgetsBinding.instance.addTimingsCallback(...)` di `main.dart`. Ambang jank
memakai budget 60 FPS = **16,67 ms**.

### 2.2 Mengapa benchmark terkontrol?

DevTools Performance tetap dipakai untuk eksplorasi awal (flame chart, frame
chart), tetapi untuk **before/after** dipakai harness yang deterministik:

- jumlah item, kecepatan scroll, dan durasi identik pada kedua build;
- metrik yang sama (`FrameTiming`) dan ambang jank eksplisit;
- tidak bergantung pada kecepatan jari/gesture manual.

Dengan begitu, selisih metrik benar-benar disebabkan oleh perubahan kode.

### 2.3 Perintah

```bash
# Profiling pada perangkat (langsung membuka /performance)
flutter run --profile -d ofscrc7dcaucssmv --dart-define=BENCHMARK_MODE=true

# Membuka benchmark dari dalam aplikasi: ikon kecepatan di AppBar NotesPage

# Verifikasi statis
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

---

## 3. Baseline Metrics (Sebelum Optimasi)

Screenshot: [`../screenshots/before-profile.png`](../screenshots/before-profile.png)

| Metrik | Baseline |
|---|---|
| Total frame | 217 |
| Frame jank (> 16,67 ms) | 95 |
| Persentase jank | 43,8% |
| Rata-rata frame time | 20,10 ms |
| P95 frame time | 34,23 ms |
| Worst frame time | 212,66 ms |
| Rata-rata build | 13,30 ms |
| Rata-rata raster | 4,75 ms |

Baseline diambil dengan `NoteTile` versi Week 10 (tanpa `const`/ekstraksi dan
tanpa `RepaintBoundary` eksplisit), pada build profile yang sama.

---

## 4. Temuan dan Akar Masalah

Detail lengkap: [`performance-findings.md`](performance-findings.md).

| Akar masalah | Dampak ke frame |
|---|---|
| `NotesPage` menonton 4 provider sekaligus | AppBar, TabBar, header, dan tab Arsitektur ikut rebuild tiap ketikan |
| Tidak ada isolasi paint pada item | repaint satu tile berpotensi memicu area lebih luas |
| Query tanpa limit + tanpa cache | pekerjaan I/O dan konversi model berulang |
| `TextEditingController` tidak di-dispose | memori naik setiap dialog dibuka |
| API key dibaca dari secure storage tiap pesan | latency platform channel |
| `imageCache` tanpa batas | risiko memori jangka panjang |
| Tidak ada index pada `updated_at` dan `dirty` | full scan + sort saat data besar |

Analisis build vs raster menunjukkan bottleneck ada di **UI thread**
(build 13,30 ms >> raster 4,75 ms), sehingga prioritas optimasi adalah
mengurangi pekerjaan build/layout, bukan optimasi GPU.

---

## 5. Optimasi yang Diterapkan

### O1. `const` constructor dan ekstraksi widget

**File:** `lib/features/notes/presentation/widgets/note_tile.dart`

- `_NoteAvatar`, `_NoteHeader`, `_NoteStatusBadge`, `_NoteSnippet`,
  `_NoteFooter`, dan `_DeleteNoteButton` diekstrak menjadi `StatelessWidget`
  dengan `const` constructor.
- Seluruh `Icon`, `SizedBox`, `TextStyle`, dan `BorderRadius` statis memakai
  `const`, sehingga tidak dialokasikan ulang pada setiap build.
- Perubahan pada satu bagian (mis. badge status) tidak memaksa seluruh
  subtree tile dibangun ulang.

### O2. `RepaintBoundary` per item

**File:** `note_tile.dart`, `ai_chat_page.dart`

- Setiap `NoteTile` dibungkus `RepaintBoundary`; setiap bubble chat juga.
- Catatan penting: `ListView.builder` sudah menambahkan boundary otomatis per
  item. Boundary eksplisit dipertahankan untuk konsistensi saat tile dipakai
  di luar `ListView`, dan tidak diklaim sebagai sumber percepatan utama.

### O3. Riverpod `select` dan `Consumer` scoped

**File:** `notes_page.dart`, `notes_providers.dart`

- `build` halaman **tidak lagi** menonton provider data.
- Label jumlah catatan pada TabBar memakai
  `ref.watch(notesProvider.select((value) => value.value?.length ?? 0))`.
- Badge dirty memakai `dirtyCountProvider.select((value) => value.value ?? 0)`
  di widget `_DirtyBadge`.
- Kolom pencarian dipisah menjadi `_NotesSearchField` yang hanya menonton
  `searchQueryProvider.select((query) => query.isNotEmpty)`.
- Area daftar dibungkus `Consumer` yang menonton `filteredNotesProvider`.
- `filteredNotesProvider` mengembalikan `notesAsync` apa adanya ketika query
  kosong (tanpa alokasi list baru).

### O4. Cache-first repository + pagination + index SQLite

**File:** `cached_note_repository.dart`, `note_repository_impl.dart`,
`note_repository.dart`, `notes_database.dart`

- `CachedNoteRepository` membungkus `NoteRepositoryImpl`:
  - halaman pertama `fetchNotes` disajikan dari cache memori;
  - `getNoteById` memakai indeks `id → Note`;
  - `countDirty` di-cache;
  - semua mutasi meng-invalidasi cache.
- `fetchNotes({limit, offset})` memakai `LIMIT/OFFSET` di SQLite.
- Database naik ke versi 2 dan menambahkan
  `idx_notes_updated_at (updated_at DESC)` serta `idx_notes_dirty (dirty)`.
  Migrasi memakai `onUpgrade` sehingga data lama tetap aman.

### O5. Perbaikan kebocoran memori & batas image cache

**File:** `notes_page.dart`, `ai_chat_page.dart`, `main.dart`

- Dialog tambah catatan dan dialog API key sekarang `await showDialog(...)`
  lalu men-`dispose()` controller di blok `finally`.
- `PaintingBinding.instance.imageCache.maximumSize = 50` dan
  `maximumSizeBytes = 24 MB`.

### O6. Cache API key AI

**File:** `lib/features/ai_chat/data/datasources/ai_remote_datasource.dart`

- `getApiKey()` menyimpan hasil pembacaan secure storage/SharedPreferences di
  `_cachedApiKey`, sehingga pesan berikutnya tidak membuka platform channel
  lagi.
- `saveApiKey()` langsung memperbarui cache.

### Ringkasan teknik vs modul

| Teknik modul | Diterapkan | Keterangan |
|---|---|---|
| `const` constructor | ✅ | O1 |
| Ekstrak widget | ✅ | O1 |
| `RepaintBoundary` | ✅ | O2 |
| Riverpod `select`/`Consumer` | ✅ | O3 |
| `ListView.builder` (lazy loading) | ✅ | sudah ada, dipertahankan |
| Pagination | ✅ | O4 (level repository, `LIMIT/OFFSET`) |
| Repository cache | ✅ | O4 (cache-first + invalidasi) |
| Batas `imageCache` | ✅ | O5 |
| `CachedNetworkImage` | ➖ | tidak ada gambar jaringan |
| Dio interceptor | ➖ | tidak ada endpoint REST kustom |

---

## 6. Hasil Verifikasi (Sesudah Optimasi)

Screenshot: [`../screenshots/after-profile.png`](../screenshots/after-profile.png)

Tiga run pengukuran dilakukan pada build optimized (aplikasi di-relaunch di
antara run) untuk memisahkan efek optimasi dari noise penjadwalan OS:

| Run | Total frame | Jank | Jank % | Avg (ms) | P95 (ms) | Worst (ms) | Build (ms) | Raster (ms) |
|---|---|---|---|---|---|---|---|---|
| 1 | 224 | 103 | 46,0% | 20,40 | 38,21 | 72,30 | 14,35 | 4,39 |
| 2 | 246 | 74 | 30,1% | 16,51 | 26,50 | 56,20 | 11,74 | 3,57 |
| 3 (median) | 225 | 95 | 42,2% | 18,31 | 30,03 | 98,62 | 13,12 | 3,63 |

Perbandingan baseline vs median after:

| Metrik | Baseline | After (median) | Perubahan |
|---|---|---|---|
| Total frame (5 detik) | 217 | 225 | +8 frame (+3,7%) |
| Frame jank | 95 | 95 | 0 |
| Persentase jank | 43,8% | 42,2% | −1,6 poin |
| Rata-rata frame time | 20,10 ms | 18,31 ms | **−1,79 ms (−8,9%)** |
| P95 frame time | 34,23 ms | 30,03 ms | **−4,20 ms (−12,3%)** |
| Worst frame time | 212,66 ms | 98,62 ms | **−114,04 ms (−53,6%)** |
| Rata-rata build | 13,30 ms | 13,12 ms | −0,18 ms (−1,4%) |
| Rata-rata raster | 4,75 ms | 3,63 ms | −1,12 ms (−23,6%) |

Interpretasi:

- Throughput frame naik (225 vs 217 frame dalam 5 detik) dan ekor distribusi
  (P95, worst) membaik jauh. Worst frame turun lebih dari separuh, artinya
  frame "macet" yang paling mengganggu mata berkurang.
- Jumlah jank tidak turun karena benchmark memaksa ~4 tile baru per frame
  (setara scroll ±37.500 px/detik). Pada kecepatan ini, biaya layout teks
  tiap tile mendominasi dan tidak dapat dihilangkan oleh micro-optimization;
  yang bisa diperbaiki adalah besarnya keterlambatan (frame time ekor).
- Varians antar-run cukup besar (jank 30–46%) karena mode profile pada
  perangkat fisik ikut dipengaruhi thermal dan penjadwalan MIUI. Karena itu
  median 3 run dipakai untuk perbandingan, bukan run terbaik.

### 6.1 Verifikasi Statis

```text
flutter analyze                     : No issues found!
dart format --set-exit-if-changed   : Formatted 49 files (0 changed)
flutter test                        : +46 All tests passed!
```

### 6.2 Memory Profiling

- Kebocoran controller pada dua dialog diperbaiki dengan `dispose()`.
- `imageCache` dibatasi 50 entri / 24 MB dan nilainya ditampilkan pada halaman
  benchmark (terbukti 0 entri pada skenario daftar catatan).
- Navigasi daftar → detail → kembali dilakukan berulang; tidak ada
  pertumbuhan objek yang tidak dibatasi karena controller dilepas saat widget
  di-`dispose()`.

---

## 7. Trade-off

| Optimasi | Keuntungan | Biaya / risiko |
|---|---|---|
| Cache-first | query SQLite jauh lebih sedikit | data bisa basi jika ada penulisan dari luar repository; dimitigasi invalidasi pada semua mutasi |
| `RepaintBoundary` per item | isolasi paint | boundary tambahan; pada `ListView` sudah otomatis sehingga manfaatnya kecil |
| `Consumer` scoped | rebuild jauh lebih sempit | struktur widget bertambah dan alur data perlu dipahami pembaca kode |
| Pagination | memori & I/O terkendali | butuh penanganan `hasMore`/offset di UI saat dataset besar |
| Batas `imageCache` | memori stabil | gambar lama bisa perlu di-decode ulang |
| Index SQLite | query terurut & filter dirty cepat | biaya tulis sedikit naik dan perlu migrasi versi DB |
| Cache API key | latency pesan turun | kunci tersimpan di memori selama proses hidup (risiko kecil pada perangkat yang sudah di-root) |

---

## 8. Rekomendasi Lanjutan

1. Terapkan infinite scroll di UI memakai `fetchNotes(limit/offset)` yang sudah
   tersedia di repository.
2. Tambahkan `cached_network_image` ketika fitur lampiran gambar diaktifkan.
3. Gunakan `itemExtent`/`prototypeItem` bila tinggi tile dapat diseragamkan;
   ini menghilangkan biaya pengukuran tinggi item saat scroll ekstrem.
4. Tambahkan integration test performa (`flutter drive`) agar regresi frame
   time terdeteksi otomatis di CI.

---

## 9. Refleksi

1. **Optimasi dengan dampak terbesar:** mempersempit cakupan rebuild (O3).
   Pada skenario nyata (mengetik pencarian, refresh, buka-tutup dialog), hanya
   area daftar/kolom pencarian yang dibangun ulang, bukan seluruh halaman.
   Pada benchmark scroll, perbaikan terlihat pada P95 dan worst frame time.
2. **Cara memverifikasi (bukan placebo):** memakai skenario benchmark yang
   identik before/after, metrik `FrameTiming` yang sama, ambang jank eksplisit,
   dan median dari beberapa run. P95 dan worst frame lebih informatif daripada
   rata-rata karena jank bersifat ekor distribusi. Kami juga tidak mengklaim
   `RepaintBoundary` sebagai penyebab utama karena `ListView.builder` sudah
   menambahkannya otomatis.
3. **Trade-off:** cache menambah kompleksitas invalidasi; `RepaintBoundary`
   menambah layer; ekstraksi widget menambah jumlah kelas; index DB menambah
   biaya tulis dan migrasi. Semua dipilih karena manfaatnya dapat diukur atau
   mencegah bug memori.
4. **Kapan optimasi prematur dihindari:** sebelum ada bukti dari profiling.
   Pada aplikasi ini optimasi gambar dan Dio interceptor sengaja tidak
   dipaksakan karena tidak ada gambar jaringan atau endpoint REST kustom.

# Temuan Pengujian — Week 12

Dokumen ini mencatat bug dan perilaku tak terduga yang **ditemukan oleh test
suite** pada aplikasi `Clean Architecture Notes` (project Week 7–11), beserta
akar masalah, perbaikan, dan test regresi yang menjaga perbaikan tersebut.

## Ringkasan

| # | Temuan | Ditemukan oleh | Status |
|---|---|---|---|
| 1 | `TextEditingController` dialog tambah catatan dipakai setelah `dispose()` | `notes_page_widget_test.dart` — skenario simpan catatan valid | Diperbaiki |
| 2 | Bug lifecycle yang sama pada dialog API Key AI | `ai_chat_widget_test.dart` — skenario simpan API key | Diperbaiki |
| 3 | Dialog tertutup saat validasi gagal sehingga input pengguna hilang | `notes_page_widget_test.dart` — skenario judul kosong | Diperbaiki |
| 4 | `Row` di dalam SnackBar overflow saat teks panjang | `notes_page_widget_test.dart` dan `note_detail_page_widget_test.dart` | Diperbaiki |
| 5 | SnackBar sukses hapus tidak konsisten terlihat setelah `Navigator.pop` pada integration test | `integration_test/app_test.dart` | Disesuaikan (lihat bagian 5) |

---

## 1. Controller dialog dipakai setelah `dispose()`

### Gejala

Test widget "menyimpan catatan valid dan menampilkannya di daftar" gagal dengan:

```text
A TextEditingController was used after being disposed.
Once you have called dispose() on a TextEditingController, it can no longer be used.

The relevant error-causing widget was:
  TextField-[<'note-body-field'>]
```

### Akar masalah

`_showAddNoteDialog()` membuat `TextEditingController` lokal, menampilkan
dialog, lalu melepas controller di blok `finally`:

```dart
final dialog = showDialog<void>(...);
try {
  await dialog;
} finally {
  titleController.dispose();
  bodyController.dispose();
}
```

Future `showDialog` selesai ketika route **mulai** ditutup, bukan setelah
animasi keluar selesai. Pada frame animasi berikutnya `TextField` masih
terpasang dan membaca controller yang sudah di-`dispose()`.

### Perbaikan

Dialog dijadikan `StatefulWidget` tersendiri (`_AddNoteDialog`) yang memiliki
controller di `State`. `dispose()` baru dipanggil ketika widget benar-benar
dilepas dari tree, yaitu setelah animasi route selesai.

```dart
class _AddNoteDialogState extends ConsumerState<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
```

### Test regresi

- `test/notes_page_widget_test.dart` → `menyimpan catatan valid dan menampilkannya di daftar`

Test ini gagal sebelum perbaikan dan lulus setelah perbaikan. Selain memeriksa
data tersimpan, test juga memastikan dialog benar-benar tertutup
(`note-title-field` tidak ditemukan), sehingga siklus hidup controller ikut
terverifikasi.

---

## 2. Bug lifecycle yang sama pada dialog API Key AI

### Gejala

Pola controller lokal + `dispose()` di `finally` juga dipakai
`_showApiKeyDialog()`. Saat dialog ditutup, `TextField` API key dapat membaca
controller yang sudah dilepas.

### Perbaikan

Dialog diekstrak menjadi `_ApiKeyDialog` (`StatefulWidget`) dengan controller
milik `State`, dan aksi simpan diserahkan lewat callback `onSave`. Halaman
induk tidak lagi memegang controller dialog.

### Test regresi

- `test/ai_chat_widget_test.dart` → `menyimpan API key lalu menutup dialog tanpa error lifecycle`

Test memasukkan `'  kunci-baru-123  '`, menekan **Simpan**, lalu memastikan:

- nilai tersimpan sudah di-trim (`kunci-baru-123`);
- SnackBar konfirmasi muncul;
- dialog tertutup tanpa exception lifecycle.

---

## 3. Dialog tertutup saat validasi gagal

### Gejala

Sebelum perbaikan, alur dialog adalah:

```dart
final result = await addNoteUseCase(title: title, body: body);
if (ctx.mounted) Navigator.pop(ctx);   // selalu menutup
if (result.failure != null) { ... }
```

Saat judul kosong, SnackBar error muncul tetapi dialog sudah tertutup. Pengguna
kehilangan seluruh isi yang sudah diketik dan harus membuka dialog lagi.

### Perbaikan

Dialog hanya ditutup bila `result.failure == null`. Bila gagal, SnackBar
ditampilkan dan dialog tetap terbuka dengan input utuh.

### Test regresi

- `test/notes_page_widget_test.dart` → `menolak judul kosong dan dialog tetap terbuka`
- `test/notes_page_widget_test.dart` → `menampilkan error repository dan tidak menutup dialog`

Kedua test memeriksa tiga hal sekaligus: pesan error tampil, field judul masih
ada, dan repository tidak menambah data.

---

## 4. SnackBar overflow

### Gejala

Test widget menampilkan error layout:

```text
A RenderFlex overflowed by 114 pixels on the right.
The relevant error-causing widget was: Row
```

### Akar masalah

Konten SnackBar berupa `Row` berisi ikon dan `Text` panjang tanpa `Expanded`.
Teks tidak dapat membungkus, sehingga `Row` melebihi lebar layar. Pada
perangkat normal teks mungkin masih muat, tetapi kombinasi layar sempit,
font besar, atau teks panjang (mis. pesan error repository) dapat memicunya.

### Perbaikan

Teks dibungkus `Expanded` pada SnackBar sukses tambah catatan, sukses update,
dan error, sehingga teks membungkus ke baris berikutnya.

### Test regresi

Test widget yang sama sekarang juga gagal bila ada overflow, karena
`flutter_test` melaporkan error layout sebagai kegagalan test.

---

## 5. SnackBar hapus tidak konsisten pada integration test

### Gejala

Integration test versi awal memeriksa teks
`'Catatan berhasil dihapus dari database lokal.'` tepat setelah halaman detail
di-pop. Pada run Windows, teks tersebut tidak ditemukan walaupun penghapusan
berhasil (halaman detail tertutup dan catatan hilang dari daftar).

### Analisis

SnackBar dikirim melalui `ScaffoldMessenger` sebelum `Navigator.pop`.
Perpindahan route dan antrean SnackBar berjalan asinkron, sehingga pada
perangkat/desktop tertentu SnackBar belum terpasang saat assertion dijalankan.
Assertion pada teks SnackBar karena itu tidak stabil.

### Penyesuaian

Integration test memverifikasi hasil yang lebih bermakna dan stabil:

- halaman detail tidak lagi tampil (`Detail & Edit Catatan` tidak ditemukan);
- catatan dengan judul unik tersebut hilang dari daftar.

Perilaku SnackBar tetap diuji di level widget, di mana waktunya deterministik.

---

## Temuan yang belum diselesaikan

| # | Temuan | Dampak | Rencana |
|---|---|---|---|
| 1 | Judul berisi *zero-width space* (`\u200B`) dianggap valid karena aturan hanya `trim().isNotEmpty` | Catatan "kosong" secara visual tetap bisa disimpan | Perketat validator dengan normalisasi karakter tak terlihat; test `validators_test.dart` sudah mendokumentasikan perilaku saat ini |
| 2 | Lapisan data SQLite (`note_repository_impl.dart`, `notes_database.dart`) 0% pada laporan coverage | Query, migrasi v1→v2, dan pemetaan model tidak diuji unit | Tambahkan test dengan `sqflite_common_ffi` in-memory |
| 3 | Integration test hanya berhasil dijalankan di Windows | Perilaku platform Android (mis. secure storage, SQLite Android) belum tercakup | Jalankan ulang di perangkat Android setelah layar dapat dibangunkan |
| 4 | `test/widget_test.dart` masih berupa placeholder bawaan | Tidak menguji apa pun, hanya menambah hitungan test | Hapus atau ganti dengan smoke test halaman utama |
| 5 | Judul aplikasi masih "Clean Architecture Notes (Week 7)" dan application id masih `com.example.week5_offline_notes` | Konsistensi penamaan modul | Perbarui saat menyentuh konfigurasi aplikasi |

---

## Kesimpulan

Dua bug yang ditemukan termasuk kategori yang paling sering lolos dari
pengujian manual: **lifecycle controller** dan **state dialog setelah aksi
gagal**. Keduanya tidak terlihat saat alur normal berjalan cepat, tetapi
muncul ketika test menunggu animasi selesai dan memeriksa kondisi tepat setelah
tombol ditekan. Perbaikan dilakukan di kode produksi, bukan dengan melonggarkan
test, dan setiap perbaikan memiliki test regresi yang gagal sebelum perubahan.

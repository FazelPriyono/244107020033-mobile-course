# #08 | Mid Project Review & Code Review

_access\_time_10 mins remaining

1.  [Selamat datang](#0)
2.  [Konsep Git Flow dan kolaborasi](#1)
3.  [Praktikum 1: Hygiene branch dan commit](#2)
4.  [Praktikum 2: PR dan peer review](#3)
5.  [Praktikum 3: Static analysis dan mid review](#4)
6.  [AI Challenge](#5)
7.  [Refactoring, testing, dan error umum](#6)
8.  [Tugas, refleksi, dan referensi](#7)

[_bug\_report_ Report a mistake](https://github.com/jti-polinema/flutter-codelab/issues)

[_close_](/)[_menu_](#)

# #08 | Mid Project Review & Code Review

_access\_time_10 mins remaining

## 1\. Selamat datang

**Terakhir diperbarui:** 4 Oktober 2026  

[Bahasa Indonesia](index.html) | [English](index-en.html)

## Tujuan pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

-   menjelaskan Git Flow dan strategi branching (`main`, `develop`, `feature/*`, `fix/*`);
-   menulis commit dan Pull Request yang berkualitas dan mudah direview;
-   melakukan peer code review yang konstruktif dengan checklist terstruktur;
-   menjalankan static analysis dan formatter (`flutter analyze`, `dart format`) hingga bersih;
-   menilai kesiapan project tengah semester dan menindaklanjuti hasil review;
-   memverifikasi saran review dari AI sebelum diterapkan.

## Persiapan

-   Laptop/PC dan repository portfolio berisi project Minggu 5–7 (`week5_offline_notes`, `campus_notify`, atau hasil refactor Clean Architecture Minggu 7). Codelab ini mereview project tersebut, bukan membuat dari nol.
-   Flutter SDK, VS Code (ekstensi Flutter/Dart), Git terkonfigurasi (`user.name` dan `user.email`).
-   Pemahaman Minggu 3 (Riverpod), Minggu 4 (repository), Minggu 6 (auth/FCM), dan Minggu 7 (Clean Architecture, dependency rule).

## 2\. Konsep Git Flow dan kolaborasi

## 1\. Branching model

Satu branch, satu tujuan:

Branch

Peran

Aturan

`main`

Selalu bisa dirilis, dilindungi

Tidak ada commit langsung; hanya via release

`develop`

Integrasi fitur mingguan

Target default semua Pull Request

`feature/*`

Kerja harian satu fitur

Pendek (< 3 hari), dari `develop`

`fix/*`

Perbaikan cepat + test

Sertakan langkah reproduksi di issue

```
main      -> selalu rilis, dilindungi
develop   -> integrasi fitur mingguan
feature/* -> kerja harian, pendek
fix/*     -> perbaikan cepat + test
```

## 2\. Commit berkualitas

Satu commit = satu perubahan logis yang bisa direview dan di-revert:

```
baik: feat(notes): validasi judul kosong + test
baik: fix(auth): refresh token sebelum retry 1x
jelek: fix bug / update / final fix beneran
```

Format `tipe(scope): deskripsi singkat` dengan tipe `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

## 3\. Anatomi Pull Request

PR kecil direview cepat; PR besar ditakuti reviewer. Syarat PR siap review:

-   Judul satu fitur, isi menjelaskan masalah → solusi → cara uji → screenshot.
-   Ukuran < 300 baris perubahan dan < 3 hari kerja.
-   `flutter analyze` bersih dan `flutter test` hijau sebelum meminta reviewer.

## 4\. Issue tracking

Setiap PR berawal dari issue yang jelas, lalu ditutup otomatis oleh PR:

```
issue #42 -> branch fix/42-login-crash
  -> commit kecil -> PR "Closes #42"
  -> review -> merge -> issue tertutup
```

## 3\. Praktikum 1: Hygiene branch dan commit

## 1\. Audit riwayat Anda

Jalankan di repository project Minggu 5–7:

```
git log --oneline -15
git branch -a
git status
```

Tandai masalah: commit langsung ke `main`, pesan `fix bug/update`, branch berumur > 1 minggu, atau file tak terlacak yang seharusnya di-commit/di-ignore.

## 2\. Buat branch kerja yang benar

```
git checkout develop
git pull origin develop
git checkout -b feat/notes-validation
# kerjakan satu perubahan kecil ...
git add -p
git commit -m "feat(notes): validasi judul kosong + test"
git push -u origin feat/notes-validation
```

Gunakan `git add -p` agar satu commit hanya memuat satu perubahan logis, bukan semua file yang tersentuh.

## 3\. Perbaiki satu commit buruk (simulasi)

Buat tabel sebelum/sesudah di `docs/review-checklist.md`: tulis ulang 3 pesan commit lama Anda menjadi format konvensional beserta alasannya. Contoh: `fix bug` → `fix(notes): cegah simpan judul kosong + test` (jelas apa, di mana, dan buktinya).

## 4\. Praktikum 2: PR dan peer review

## 1\. Buka PR kecil

Dari branch `feat/notes-validation`, buka PR ke `develop` dengan template:

```
Judul: feat(notes): validasi judul kosong + test
Masalah: pengguna bisa menyimpan catatan tanpa judul.
Solusi: validasi di use case + pesan error di UI.
Cara uji: 1) tambah catatan kosong -> error muncul.
  2) flutter test test/validate_note_test.dart
Closes #12
```

## 2\. Review sejawat 15 menit

Tukar PR dengan pasangan. Reviewer wajib menghasilkan minimal:

-   2 temuan kebenaran (null, state, error path, edge case).
-   1 temuan arsitektur (import lintas layer, DI bocor, model bocor ke UI).
-   1 temuan test (kasus sukses/gagal kurang) dan 1 saran keterbacaan.
-   Keputusan akhir: **Approve** atau **Request changes**.

## 3\. Komentar yang baik

Gunakan pola **observasi → dampak → usulan konkret**:

```
Kurang: "kode ini jelek, perbaiki"
Baik: "Fungsi build 60 baris + 3 tanggung jawab.
  Usul: pecah validasi ke core/validate.dart.
  Alasan: bisa diunit-test tanpa widget."
```

Bersikap keras pada kode, baik pada manusia. Setiap komentar harus bisa ditindaklanjuti tanpa bertanya ulang.

## 4\. Tindak lanjut dan merge

Author memperbaiki, me-request re-review, lalu merge dengan _squash_ bila commit perantara berantakan. Pastikan issue tertutup otomatis dan branch dihapus setelah merge agar daftar branch tetap pendek.

## 5\. Praktikum 3: Static analysis dan mid review

## 1\. Bersihkan dengan mesin

Jalankan tiga perintah ini di project Anda; semuanya harus hijau sebelum PR diminta review:

```
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

Contoh bacaan output: `unused_import` → hapus import mati; `prefer_const` → pakai `const` agar rebuild murah; `must_be_immutable` → widget tidak boleh mutable. Perbaiki dari error dulu, lalu warning, lalu info.

## 2\. Aktifkan penolakan otomatis (CI)

Buat `.github/workflows/ci.yml` minimal agar PR kotor ditolak mesin sebelum dibaca manusia:

```
name: ci
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter analyze
      - run: flutter test
```

## 3\. Nilai kesiapan tengah semester

Isi `docs/review-checklist.md`: struktur feature-first terbukti (hasil tiga grep sterilitas Minggu 7), analyze bersih, test hijau, PR kecil + commit jelas, README + screenshot + cara menjalankan lengkap, dan semua komentar review sudah ditindaklanjuti. Yang dinilai bukan banyaknya fitur, melainkan fondasi yang bisa dipercaya untuk paruh kedua.

## 6\. AI Challenge

## Peran AI pada codelab ini

AI boleh menjadi reviewer awal yang cepat dan teliti, tetapi **Anda yang memutuskan**. Review AI yang salah (menuduh bug yang tidak ada, menyarankan pola yang melanggar arsitektur) lebih berbahaya daripada tidak ada review.

## AI Prompt Challenge

Minta AI coding assistant dengan prompt berikut pada PR Anda:

```
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

## AI Verification Checklist

Sebelum saran AI diterapkan, verifikasi dan catat di `docs/ai-review-vs-keputusan.md`:

-   Apakah temuan benar-benar ada? Buktikan dengan grep, test gagal, atau reproduksi manual.
-   Apakah usulan melanggar dependency rule (domain mengimpor Flutter/Dio/SQLite)? Tolak bila ya.
-   Apakah AI hanya nitpick style yang seharusnya ditangani formatter/CI?
-   Minimal 2 temuan AI terbukti benar dengan bukti, dan minimal 1 temuan ditolak dengan alasan tertulis.
-   Keputusan final dan alasan teknis Anda, boleh berbeda dari saran AI selama berargumen.

## 7\. Refactoring, testing, dan error umum

## Refactoring Challenge

1.  Terapkan seluruh komentar _request changes_ dari reviewer sejawat, lalu minta re-review hingga _approve_. Jangan merge PR berstatus request changes.
2.  Pindahkan semua temuan style berulang ke otomatisasi: rapikan `dart format` dan pastikan CI menolak PR kotor.
3.  Perkecil satu PR besar (> 300 baris) menjadi 2–3 PR kecil berurutan yang masing-masing bisa direview < 15 menit.

## Testing: review tanpa dijalankan tidak sah

Setiap PR yang mengubah perilaku wajib menyertakan bukti uji:

```
flutter analyze
flutter test
# + langkah manual 5 menit per fitur + screenshot
```

## Error umum dan solusinya

Gejala

Penyebab umum

Solusi

PR 800 baris tak kunjung direview

Banyak fitur digabung satu PR

Pecah per fitur; satu PR < 300 baris

Konflik merge berulang

Branch berumur panjang, jarang sinkron

Rebase/pull `develop` harian; branch < 3 hari

Review hanya debat spasi

Tidak ada formatter/CI

Wajibkan `dart format` + CI analyze

`approve` tapi bug lolos

Review tanpa pull + test

Reviewer wajib checkout, jalankan, dan uji manual

Saran AI merusak arsitektur

AI diterima mentah tanpa verifikasi

Tolak dengan alasan + bukti grep/test

## Checklist verifikasi mandiri

-   Branch dari `develop`, PR kecil satu fitur, issue tertutup via PR.
-   Minimal 3 komentar review bermakna sudah ditindaklanjuti hingga approve.
-   `flutter analyze` bersih, `dart format` rapi, `flutter test` hijau.
-   Tabel usulan AI vs keputusan final terdokumentasi di `docs/`.

## 8\. Tugas, refleksi, dan referensi

## Mini project / Industry Challenge

Lanjutkan repository portfolio Anda (lanjutkan project Minggu 5–7, bukan project baru) dan buktikan disiplin kolaborasi:

1.  Buat minimal 1 issue + 1 PR kecil yang di-merge via review sejawat (branch `feature/*` → `develop`).
2.  Sertakan template PR lengkap: masalah, solusi, cara uji, dan screenshot.
3.  Bukti mesin hijau: hasil `flutter analyze` + `flutter test` di README.
4.  Dokumentasikan prompt AI, tabel usulan-vs-keputusan-final, dan bukti penolakan/penerimaan di `docs/`.
5.  Push ke folder portfolio `08-week-8-mid-project-review/` dengan struktur `docs/`, `README.md`, dan `screenshots/`. README menjelaskan status paruh semester, peta issue/PR, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.

## Refleksi

-   Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?
-   Kapan komentar wajib berstatus _request changes_, dan kapan cukup saran?
-   Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?
-   Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?

## Referensi pendukung

-   [Slide Week 8: Mid Project Review & Code Review](../00-slides/Week_08_Mid_Project_Review_Code_Review.html)
-   [Atlassian: GitFlow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
-   [GitHub: About pull request reviews](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
-   [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
-   [Flutter: Static analysis & IDE integration](https://docs.flutter.dev/tools/using-ide)
-   [Dart: Linter rules](https://dart.dev/tools/linter-rules)
-   [GitHub Actions documentation](https://docs.github.com/en/actions)
-   [Learn Dart in Y Minutes](https://learnxinyminutes.com/dart/)

[Back](# "Previous step")

[Next](# "Next step")[Done](/ "Codelab complete")
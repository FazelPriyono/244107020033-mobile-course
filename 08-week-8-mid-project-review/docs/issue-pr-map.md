# Peta Issue / PR — Manual (Siap Dibuka)

Karena `gh` CLI belum terpasang, issue dan PR dibuat melalui web GitHub (`FazelPriyono/244107020033-mobile-course`). Berikut isi siap salin.

---

## Issue #1 — Track `pubspec`, `analysis_options`, dan test Week 7

**Judul:** `chore: project Week 7 tidak bisa dijalankan/diuji dari clone`

**Body:**
```markdown
## Masalah
Root `.gitignore` mengabaikan `pubspec.yaml`, `analysis_options.yaml`, `pubspec.lock`, dan folder `test/` untuk seluruh sub-project. Akibatnya clone repo tidak bisa menjalankan `flutter pub get` maupun `flutter test` pada `07-week-7-clean-architecture`.

## Solusi
Tambahkan negasi `.gitignore` khusus Week 7 dan commit file konfigurasi yang hilang.

## Cara uji
1. Clone ulang repo
2. `flutter pub get` berhasil
3. `flutter test` hijau

## Bukti
Branch `chore/1-track-project-files` sudah siap (commit `4e551c5`).
```

---

## PR #1 — `chore/1-track-project-files` → `develop`

**Judul:** `chore(repo): track pubspec, analysis_options, dan test Week 7`

**Body:**
```markdown
Masalah: file konfigurasi dan test tidak ter-track sehingga project tidak reproducible.
Solusi: negasi `.gitignore` khusus Week 7 + commit pubspec, lockfile, analysis_options, dan nested `.gitignore`.
Cara uji:
1) `git clone ... && cd 07-week-7-clean-architecture`
2) `flutter pub get`
3) `flutter test`
Closes #1
```

---

## Issue #2 — `UpdateNote` Trim

**Judul:** `fix(notes): UpdateNote tidak melakukan trim judul/isi`

**Body:**
```markdown
Masalah: `UpdateNote` memvalidasi judul kosong, tetapi meneruskan catatan apa adanya ke repository (`note` tanpa `trim`). Akibatnya judul/isi dengan spasi tersembunyi tersimpan.
Solusi: `trim()` judul dan isi sebelum `_repository.updateNote()`.
Cara uji: lihat `test/update_note_test.dart` (3 test baru).
```

---

## PR #2 — `fix/2-update-note-trim` → `develop`

**Body:**
```markdown
Masalah: judul/isi hasil edit masih menyimpan spasi berlebih.
Solusi: `trim()` judul dan isi pada `UpdateNote`.
Cara uji:
- `flutter test` → semua hijau termasuk 3 test baru (`UpdateNote`)
- Edit catatan dengan judul `"  Belanja  "` → tersimpan `"Belanja"`
Closes #2
```

---

## Issue #3 — CI Workflow

**Judul:** `chore(ci): tambah workflow analyze, format, dan test`

**Body:**
```markdown
Masalah: tidak ada verifikasi otomatis sebelum PR di-review.
Solusi: `.github/workflows/ci.yml` dengan `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, menggunakan `working-directory: 07-week-7-clean-architecture`.
```

---

## PR #3 — `chore/3-ci` → `develop`

**Body:**
```markdown
Masalah: PR kotor tidak ditolak mesin sebelum dibaca manusia.
Solusi: CI `flutter analyze`, `dart format`, `flutter test`.
Closes #3
```

---

## Issue #4 — Dokumentasi Mid Project Review

**Judul:** `docs(week-8): laporan mid project review + AI review`

**Body:**
```markdown
Masalah: belum ada dokumentasi tengah semester, checklist review, dan tabel AI vs keputusan final.
Solusi: folder `08-week-8-mid-project-review/` dengan `README.md`, `docs/review-checklist.md`, `docs/ai-review-vs-keputusan.md`, `docs/issue-pr-map.md`, dan `screenshots/`.
```

---

## PR #4 — `docs/4-week-8-report` → `develop`

**Body:**
```markdown
Masalah: belum ada laporan paruh semester, peta issue/PR, dan bukti verifikasi.
Solusi: lengkapkan `README.md` + dokumen pendukung dengan bukti mesin hijau (`analyze-final.txt`, `format-final.txt`, `test-final.txt`, `sterility-checks.txt`).
```

---

## Catatan Push & PR

Karena `gh` belum tersedia, lakukan secara manual:

```powershell
# 1. Push semua branch
git push -u origin develop
git push -u origin chore/1-track-project-files
git push -u origin fix/2-update-note-trim
git push -u origin chore/3-ci
git push -u origin docs/4-week-8-report

# 2. Buat issue dan PR melalui web GitHub (https://github.com/FazelPriyono/244107020033-mobile-course)
#    - Salin judul dan body dari file ini.
#    - Gunakan label `feature`, `bug`, atau `docs` sesuai isi.
```

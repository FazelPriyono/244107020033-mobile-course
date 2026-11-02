# Review Checklist — Mid Project Review Week 8

## 1. Audit Riwayat

### git log --oneline -15 (sebelum PR Week 8)

```
27ae786 fix(notes): trim judul dan isi pada UpdateNote + test
4e551c5 chore(repo): track pubspec, analysis_options, dan test Week 7
5553659 docs(week-7): rapikan laporan verifikasi sterilitas
932a352 style(week-7): terapkan dart format pada lib dan test
edf1e8a chore: remove week7.md
f7169b4 docs(week-7): update README with detailed sterility checks...
9d12aa6 feat(week-7): implement Clean Architecture feature-first...
78ea655 docs: format output screenshots as a table
bb0906d feat: add week 6 authentication security and fcm
8a31006 chore: cleaning ignore list
3721e0c chore: ignore unused boilerplate and generated files across all weeks
476d42e chore: untrack desktop.ini and ignore it
3a24101 chore: remove redundantly copied directories
a53dc70 docs: format output screenshots as a table in README.md
```

### git branch -a (setelah pembuatan branch Week 8)

```
* docs/4-week-8-report
  chore/1-track-project-files
  chore/3-ci
  develop
  fix/2-update-note-trim
  main
  remotes/origin/main
```

### git status --short (pada `docs/4-week-8-report`)

```
?? 08-week-8-mid-project-review/
```

---

## 2. Perbaikan Commit

| Sebelum | Sesudah | Alasan |
|---|---|---|
| `chore: cleaning ignore list` | `chore(repo): rapikan .gitignore artefak build dan metadata` | Scope jelas |
| `chore: remove redundantly copied directories` | `chore(repo): hapus duplikasi folder project` | Scope jelas |
| `docs: format output screenshots as a table` | `docs(week-7): format output screenshots as a table in README.md` | Tipe + scope |

---

## 3. Pemeriksaan Mesin

### `flutter analyze`
```
Analyzing 07-week-7-clean-architecture...
No issues found! (ran in 3.3s)
```
Bukti: [`docs/evidence/analyze-final.txt`](evidence/analyze-final.txt)

### `dart format`
```
Formatted 31 files (0 changed) in 0.13 seconds.
```
Bukti: [`docs/evidence/format-final.txt`](evidence/format-final.txt)

### `flutter test`
```
00:00 +19: All tests passed!
```
Bukti: [`docs/evidence/test-final.txt`](evidence/test-final.txt)

### `flutter test` setelah PR #2 (UpdateNote trim + test baru)
```
00:00 +17: UpdateNote UseCase Test...
00:00 +19: All tests passed!
```
Bukti: [`docs/evidence/test-update-note.txt`](evidence/test-update-note.txt)

---

## 4. Verifikasi Sterilitas Layer

Metode: `ripgrep` (`rg`) dijalankan pada struktur `07-week-7-clean-architecture/lib/features/`.
`lib/pages` tidak ada pada struktur feature-first, sehingga hanya dua direktori presentation (`notes` dan `settings`) yang diperiksa.

Bukti lengkap: [`docs/evidence/sterility-checks.txt`](evidence/sterility-checks.txt)

### Hasil ringkas

| Perintah | Hasil | Status |
|---|---|---|
| `rg ... lib/features/*/presentation` | 0 matches | ✅ Steril |
| `rg ... lib/features/*/domain lib/core` | 0 matches | ✅ Steril |
| `rg ... lib/features/*/presentation/pages lib/features/*/presentation/widgets` | 0 matches | ✅ Steril |

---

## 5. Checklist Kesiapan

| Kriteria | Bukti | Status |
|---|---|---|
| Aplikasi berjalan identik dengan akhir Minggu 7 | `README.md` §3 | ✅ |
| Struktur feature-first terbukti (`domain` <-> `data` <-> `presentation`) | `lib/features/notes/` | ✅ |
| `flutter analyze` bersih | `docs/evidence/analyze-final.txt` | ✅ |
| `dart format` bersih (0 changed) | `docs/evidence/format-final.txt` | ✅ |
| `flutter test` hijau | `docs/evidence/test-final.txt` (19 test) | ✅ |
| 3 perintah grep sterilitas 0 hasil | `docs/evidence/sterility-checks.txt` | ✅ |
| PR kecil (< 300 baris) sudah di-merge | `chore/1-track...`, `fix/2-update...`, `chore/3-ci` | ✅ (simulasi lokal) |
| Commit berkualitas (`tipe(scope): ...`) | `git log --oneline` | ✅ |
| Branch `feature/*` atau `fix/*` dari `develop` | `git branch -a` | ✅ |
| Issue terhubung dengan PR (`Closes #...`) | `docs/issue-pr-map.md` | ⏳ Menunggu pembuatan GitHub |
| Review minimal 3 komentar bermakna | `docs/review-checklist.md` §6 | ✅ (simulasi mandiri) |
| `README.md` lengkap | `08-week-8-mid-project-review/README.md` | ✅ |
| Tabel AI vs keputusan final | `docs/ai-review-vs-keputusan.md` | ✅ |
| Screenshot `flutter analyze` + `flutter test` | `screenshots/hasil-analyze-test-week7.png` | ✅ |
| `docs/review-checklist.md` lengkap | `docs/review-checklist.md` | ✅ |
| `docs/ai-review-vs-keputusan.md` lengkap | `docs/ai-review-vs-keputusan.md` | ✅ |

---

## 6. Catatan Batasan Simulasi

Karena `gh` CLI tidak tersedia dan tidak ada akses otomatis ke GitHub Actions, langkah ini masih memerlukan tindakan manual oleh pemilik akun:

1. **Push branch** (`develop`, `chore/*`, `fix/*`, `chore/3-ci`, `docs/4-week-8-report`) ke remote.
2. **Buat Issue** menggunakan body dari [`docs/issue-pr-map.md`](issue-pr-map.md).
3. **Buka PR** ke `develop` (retarget setelah PR #1 merge).
4. **Tambahkan komentar review** (simulasi atau sejawat) di setiap PR.
5. **Merge** PR dengan `squash` (bila perlu) dan hapus branch.
6. **Tambahkan screenshot CI** (`.github/workflows/ci.yml`) setelah PR #3 di-merge.
7. Perbarui status PR di `README.md` setelah semua PR benar-benar di-merge.

---

## 7. Bukti Output Terminal (Ringkasan)

- [`docs/evidence/analyze-final.txt`](evidence/analyze-final.txt) — `No issues found!`
- [`docs/evidence/format-final.txt`](evidence/format-final.txt) — `0 changed`
- [`docs/evidence/test-final.txt`](evidence/test-final.txt) — `+19: All tests passed!`
- [`docs/evidence/test-update-note.txt`](evidence/test-update-note.txt) — `+19: All tests passed!` (termasuk 3 test baru)
- [`docs/evidence/sterility-checks.txt`](evidence/sterility-checks.txt) — 3 perintah `0 matches`

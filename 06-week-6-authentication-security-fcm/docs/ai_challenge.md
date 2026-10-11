# AI Challenge - Dokumentasi

## Prompt yang digunakan

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## Output awal AI

AI menghasilkan draf `push_service.dart` yang cukup lengkap. Namun ada beberapa hal yang perlu diverifikasi:

1. Background handler dihasilkan sebagai fungsi top-level dengan `@pragma('vm:entry-point')` — **DITERIMA**.
2. `onTokenRefresh` memanggil fungsi `onToken` yang diteruskan via parameter — **DITERIMA**, token tidak hardcode maupun di-log penuh.
3. Foreground menggunakan `flutter_local_notifications` secara manual — **DITERIMA**.
4. `routeFromMessage` diekstrak sebagai fungsi murni — **DITERIMA**, dapat diunit-test tanpa Firebase.

## Perbaikan manual

- Token tidak di-log secara penuh; hanya panjang token yang dicetak (`debugPrint('[FCM] Token diterima (${token.length} karakter)')`).
- Ditambahkan `try-catch` di `main.dart` agar aplikasi tetap berjalan meskipun Firebase belum dikonfigurasi.
- `pendingDeepLink` direset ke `null` setelah digunakan di `handleTerminated` untuk menghindari navigasi ganda.
- Semua string rute dipindah ke `lib/routes.dart` — AI tidak menyertakan ini.

## AI Verification Checklist

| Kriteria | Status | Catatan |
|---|---|---|
| Background handler top-level + `@pragma` | Lulus | Lihat `push_service.dart` |
| `onTokenRefresh` benar-benar kirim ke backend | Lulus (mock) | TODO endpoint nyata |
| Foreground pakai local notification manual | Lulus | `onMessage` → `_local.show()` |
| Klik dari 3 state masuk rute yang benar | Perlu uji fisik | Lihat tabel di README |
| Token tidak hardcode / tidak di-log penuh | Lulus | Hanya panjang token |
| Keputusan berbeda dari AI | - | String rute dipindah ke konstanta |

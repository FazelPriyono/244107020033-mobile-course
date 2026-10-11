import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:campus_notify/routes.dart';

// ---------------------------------------------------------------------------
// Instance lokal — diakses dari dalam file ini saja.
// ---------------------------------------------------------------------------
final _local = FlutterLocalNotificationsPlugin();

/// Menyimpan data notifikasi sementara router belum siap.
String? pendingDeepLink;
String? pendingNotificationTitle;
String? pendingNotificationBody;

typedef NotificationNavigateCallback = void Function(
  String route, {
  String? title,
  String? body,
});

// ---------------------------------------------------------------------------
// Praktikum 2 §1 — Minta izin notifikasi (Android 13+ dan iOS wajib runtime).
// ---------------------------------------------------------------------------

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

// ---------------------------------------------------------------------------
// Praktikum 2 §1 — Inisialisasi flutter_local_notifications.
// Local notification WAJIB untuk foreground karena sistem tidak tampilkan
// banner otomatis saat aplikasi sedang terbuka.
// ---------------------------------------------------------------------------

Future<void> initLocalNotifications({
  NotificationNavigateCallback? onSelectNotification,
}) async {
  // Android: pakai ikon launcher bawaan.
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  // iOS: pakai setting default, APNs diurus Firebase.
  const ios = DarwinInitializationSettings();

  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        String route = payload;
        String? title;
        String? body;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            route = (decoded['route'] as String?) ?? payload;
            title = decoded['title'] as String?;
            body = decoded['body'] as String?;
          }
        } catch (_) {}

        pendingDeepLink = route;
        pendingNotificationTitle = title;
        pendingNotificationBody = body;
        onSelectNotification?.call(route, title: title, body: body);
      }
    },
  );
}

// ---------------------------------------------------------------------------
// Praktikum 2 §3 — Token lifecycle: ambil, kirim ke backend, pantau perubahan.
// ---------------------------------------------------------------------------

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  // 1. Ambil token saat ini.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada; jika tidak backend menyimpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Berlangganan topik untuk broadcast ke semua mahasiswa.
  await FirebaseMessaging.instance
      .subscribeToTopic('pengumuman-kampus');
}

// ---------------------------------------------------------------------------
// Praktikum 3 §1 — Background handler.
// WAJIB top-level (bukan method kelas) karena berjalan di isolate terpisah.
// Jangan akses BuildContext / Riverpod di sini.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tugas background handler: catat atau simpan ringan saja.
  // Navigasi dilakukan saat pengguna mengklik banner (onMessageOpenedApp).
  // ignore: avoid_print
  print('[FCM] Background message id: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ---------------------------------------------------------------------------
// Praktikum 3 §2 — Tiga handler state.
// ---------------------------------------------------------------------------

/// Parses data payload menjadi rute. Fungsi murni — dapat diunit-test.
String routeFromMessage(Map<String, dynamic> data) {
  final route = (data['route'] as String?) ??
      (data['id'] != null ? '/pengumuman/${data['id']}' : AppRoutes.home);
  return route.startsWith('/') ? route : '/$route';
}

/// Helper untuk mengekstrak title dari RemoteMessage (baik dari notification maupun data)
String? extractTitle(RemoteMessage message) {
  return message.notification?.title ??
      (message.data['title'] as String?);
}

/// Helper untuk mengekstrak body dari RemoteMessage (baik dari notification maupun data)
String? extractBody(RemoteMessage message) {
  return message.notification?.body ??
      (message.data['body'] as String?) ??
      (message.data['message'] as String?) ??
      (message.data['content'] as String?);
}

/// Handler foreground (aplikasi terbuka) dan background→diklik.
void listenForeground(NotificationNavigateCallback go) {
  // FOREGROUND: sistem TIDAK menampilkan banner otomatis.
  // Tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    final title = extractTitle(message) ?? 'Pengumuman';
    final body = extractBody(message) ?? '';

    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );

    final payload = jsonEncode({
      'route': route,
      'title': title,
      'body': body,
    });

    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  });

  // BACKGROUND → diklik: sistem sudah menampilkan banner, tinggal navigasi.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = routeFromMessage(message.data);
    final title = extractTitle(message);
    final body = extractBody(message);

    pendingNotificationTitle = title;
    pendingNotificationBody = body;
    go(route, title: title, body: body);
  });
}

/// Handler state terminated: aplikasi dibuka dari klik notifikasi.
Future<void> handleTerminated(NotificationNavigateCallback go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    final route = routeFromMessage(initial.data);
    final title = extractTitle(initial);
    final body = extractBody(initial);

    pendingNotificationTitle = title;
    pendingNotificationBody = body;
    go(route, title: title, body: body);
    return;
  }

  if (pendingDeepLink != null) {
    go(
      pendingDeepLink!,
      title: pendingNotificationTitle,
      body: pendingNotificationBody,
    );
    pendingDeepLink = null;
  }
}

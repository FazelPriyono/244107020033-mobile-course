import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

// ---------------------------------------------------------------------------
// Background handler HARUS didaftarkan sebelum runApp dan sebelum WidgetsBinding.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _backgroundHandler(dynamic message) async =>
    firebaseMessagingBackgroundHandler(message);

// ---------------------------------------------------------------------------
// ProviderContainer global untuk GoRouter redirect (tidak bisa pakai ref di sana).
// ---------------------------------------------------------------------------
final _container = ProviderContainer();

void _navigateTo(String route, {String? title, String? body}) {
  final extra = <String, dynamic>{};
  if (title != null) extra['title'] = title;
  if (body != null) extra['body'] = body;
  _router.go(
    route,
    extra: extra.isNotEmpty ? extra : null,
  );
}

// ---------------------------------------------------------------------------
// GoRouter
// ---------------------------------------------------------------------------
final _router = GoRouter(
  refreshListenable: _AuthStateListenable(_container),
  redirect: (context, state) {
    final loggedIn = _container.read(authStateProvider).value ?? false;
    final goingLogin = state.matchedLocation == AppRoutes.login;
    if (!loggedIn && !goingLogin) return AppRoutes.login;
    if (loggedIn && goingLogin) {
      if (pendingDeepLink != null) {
        final target = pendingDeepLink!;
        pendingDeepLink = null;
        return target;
      }
      return AppRoutes.home;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, _) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, _) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.announcement,
      builder: (context, s) {
        final extra = s.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String? ??
            s.uri.queryParameters['title'] ??
            pendingNotificationTitle;
        final body = extra?['body'] as String? ??
            s.uri.queryParameters['body'] ??
            pendingNotificationBody;
        return AnnouncementPage(
          id: s.pathParameters['id'] ?? '',
          title: title,
          body: body,
        );
      },
    ),
  ],
);

// ---------------------------------------------------------------------------
// Listenable untuk GoRouter agar redirect dipanggil ulang saat auth berubah.
// ---------------------------------------------------------------------------
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(ProviderContainer container) {
    container.listen<AsyncValue<bool>>(authStateProvider, (prev, _) {
      notifyListeners();
    });
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Firebase init ----
  try {
    await Firebase.initializeApp();
    registerBackgroundHandler();
    await requestNotificationPermission();
    await initLocalNotifications(
      onSelectNotification: (route, {title, body}) =>
          _navigateTo(route, title: title, body: body),
    );
    await initFcmToken(onToken: (token) async {
      debugPrint('[FCM] Token diterima (${token.length} karakter)');
    });
    listenForeground(
      (route, {title, body}) => _navigateTo(route, title: title, body: body),
    );
  } catch (e) {
    debugPrint('[Firebase] Tidak terkonfigurasi: $e');
  }

  // Pastikan auth state awal selesai dimuat dari secure storage
  await _container.read(authStateProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const MyApp(),
    ),
  );

  // Jika app dibuka dari kondisi mati (terminated) lewat notifikasi
  WidgetsBinding.instance.addPostFrameCallback((_) {
    handleTerminated(
      (route, {title, body}) => _navigateTo(route, title: title, body: body),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

/// Konstanta semua rute aplikasi.
/// Dipakai bersama oleh GoRouter dan FCM deep link
/// agar tidak ada string rute yang tersebar di berbagai file.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';

  /// Buat path konkret untuk rute pengumuman dengan id tertentu.
  static String announcementPath(String id) => '/pengumuman/$id';
}

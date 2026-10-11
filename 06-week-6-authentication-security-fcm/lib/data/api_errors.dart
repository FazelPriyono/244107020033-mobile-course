import 'package:dio/dio.dart';

/// Mengubah [DioException] menjadi pesan ramah pengguna.
/// UI hanya menerima [String] pesan, bukan exception mentah.
String friendlyDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return 'Koneksi timeout. Periksa jaringan Anda.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }
  switch (e.response?.statusCode) {
    case 400:
      return 'Permintaan tidak valid. Periksa data yang dikirim.';
    case 401:
      return 'Sesi habis. Silakan login kembali.';
    case 403:
      return 'Anda tidak memiliki izin untuk aksi ini.';
    case 404:
      return 'Data tidak ditemukan.';
    case 500:
      return 'Terjadi kesalahan server. Coba lagi nanti.';
    default:
      return 'Terjadi kesalahan. Kode: ${e.response?.statusCode ?? 'unknown'}';
  }
}

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier ini mengelola proses pengambilan data statistik secara asynchronous.
class StatsNotifier extends AsyncNotifier<List<String>> {
  // Callback dan delay dapat diatur pada test supaya hasilnya deterministik.
  StatsNotifier({this.delay = const Duration(seconds: 2), this.shouldFail});

  // Delay default dua detik mensimulasikan waktu respons dari server.
  final Duration delay;

  // Callback opsional ini hanya membantu test memaksa kondisi tertentu.
  final bool Function()? shouldFail;

  @override
  Future<List<String>> build() async {
    // Menunggu dua detik untuk mensimulasikan pengambilan data dari server.
    await Future<void>.delayed(delay);

    // Secara normal, request gagal secara acak dengan kemungkinan 30 persen.
    final failed = shouldFail?.call() ?? Random().nextDouble() < 0.3;
    if (failed) {
      // Exception ini akan diteruskan Riverpod ke kondisi AsyncError.
      throw Exception('Gagal memuat data statistik');
    }

    // Tiga item berikut adalah data statistik yang ditampilkan oleh halaman.
    return [
      'Total pengguna: 1.250',
      'Pesanan hari ini: 86',
      'Pendapatan: Rp12.500.000',
    ];
  }
}

// Provider ini membuat StatsNotifier dan menyediakan state AsyncValue ke UI.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);

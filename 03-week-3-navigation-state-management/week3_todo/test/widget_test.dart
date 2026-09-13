// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_todo/pages/stats_page.dart';
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  testWidgets('menampilkan loading saat statistik sedang dimuat', (
    WidgetTester tester,
  ) async {
    // Delay satu detik menjaga provider tetap loading pada frame pertama.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(
              delay: const Duration(seconds: 1),
              shouldFail: () => false,
            ),
          ),
        ],
        child: const MaterialApp(home: StatsPage()),
      ),
    );

    // Frame awal harus menampilkan indikator loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Habiskan timer agar tidak ada timer tertinggal saat test selesai.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('menampilkan tiga statistik saat request berhasil', (
    WidgetTester tester,
  ) async {
    // Delay nol membuat test sukses berjalan cepat.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(delay: Duration.zero, shouldFail: () => false),
          ),
        ],
        child: const MaterialApp(home: StatsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Ketiga item statistik harus tampil pada kondisi success.
    expect(find.text('Total pengguna: 1.250'), findsOneWidget);
    expect(find.text('Pesanan hari ini: 86'), findsOneWidget);
    expect(find.text('Pendapatan: Rp12.500.000'), findsOneWidget);
  });

  testWidgets('menampilkan pesan error dan tombol retry', (
    WidgetTester tester,
  ) async {
    // shouldFail true memaksa provider masuk ke kondisi error.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(delay: Duration.zero, shouldFail: () => true),
          ),
        ],
        child: const MaterialApp(home: StatsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Pesan error dan tombol retry harus tersedia untuk pengguna.
    expect(find.textContaining('Gagal memuat statistik'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  test(
    'StatsNotifier mengembalikan tiga statistik saat request berhasil',
    () async {
      // Delay nol membuat unit test tidak perlu menunggu simulasi dua detik.
      final notifier = StatsNotifier(
        delay: Duration.zero,
        shouldFail: () => false,
      );

      // build dipanggil langsung untuk menguji logika notifier tanpa widget.
      final stats = await notifier.build();

      expect(stats, hasLength(3));
      expect(stats.first, 'Total pengguna: 1.250');
    },
  );

  test('StatsNotifier melempar error saat request gagal', () async {
    // Callback ini memaksa kondisi gagal agar test tidak bergantung pada random.
    final notifier = StatsNotifier(
      delay: Duration.zero,
      shouldFail: () => true,
    );

    // Error dari build adalah error yang akan menjadi AsyncError di Riverpod.
    expect(notifier.build(), throwsA(isA<Exception>()));
  });
}

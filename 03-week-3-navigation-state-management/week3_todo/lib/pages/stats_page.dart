import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget diperlukan agar halaman dapat membaca perubahan dari Riverpod.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch membuat UI dibangun ulang setiap kali state statistik berubah.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      // AsyncValue.when memisahkan tampilan loading, error, dan success.
      body: statsAsync.when(
        // Spinner ditampilkan selama data masih diambil.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Pesan error dan tombol retry ditampilkan jika request gagal.
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat statistik: $error'),
              const SizedBox(height: 8),
              FilledButton(
                // invalidate menjalankan ulang provider saat tombol ditekan.
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // ListView menampilkan tiga item statistik setelah request berhasil.
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(stats[index]),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_provider.dart';

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau perubahan state pada productsProvider
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: productsAsync.when(
        // Kondisi 1: Saat data sedang dimuat (loading)
        loading: () => const Center(child: CircularProgressIndicator()),

        // Kondisi 2: Saat terjadi error/gagal
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              const SizedBox(height: 8),
              FilledButton(
                // Tombol Coba Lagi menggunakan ref.invalidate untuk memuat ulang provider
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),

        // Kondisi 3: Saat data berhasil didapatkan (success)
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(products[index]));
          },
        ),
      ),
    );
  }
}

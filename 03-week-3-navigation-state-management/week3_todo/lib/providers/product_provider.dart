import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Membuat Notifier untuk data asinkron berbasis List<String>
class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Simulasi network delay selama 2 detik
    await Future.delayed(const Duration(seconds: 2));
    
    // (Uji Coba Langkah 2): baris di bawah ini untuk menguji kondisi Error
    // throw Exception('Gagal terhubung ke server!');

    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  // Fungsi untuk refresh data
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 2));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

// 2. Mendeklarasikan provider-nya
final productsProvider = 
    AsyncNotifierProvider<ProductsNotifier, List<String>>(
  ProductsNotifier.new,
);
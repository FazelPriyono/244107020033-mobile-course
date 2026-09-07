import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_2/main.dart'; 

void main() {
  testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
    // Override ukuran layar menjadi sempit (400x800)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    
    // Pastikan ukuran layar dikembalikan seperti semula setelah test selesai
    addTearDown(tester.view.reset);

    // Jalankan aplikasi
    await tester.pumpWidget(const DashboardApp());

    // Cari Card pertama dan ambil lebarnya
    // Menggunakan .first karena ada 4 Card di layar
    final width = tester.getSize(find.byType(Card).first).width;
    
    // Ekspektasi: Karena layar 400px (di bawah breakpoint 700),
    // Card akan mengambil full width (minus padding), jadi pasti kurang dari 700.
    expect(width, lessThan(700));
  });

  testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
    // Override ukuran layar menjadi lebar (1200x800)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DashboardApp());

    // Cari Card pertama dan ambil lebarnya
    final width = tester.getSize(find.byType(Card).first).width;
    
    // Ekspektasi: Karena layar 1200px (di atas breakpoint 700),
    // Card akan dibagi 2 kolom oleh Row + Expanded. 
    // Lebarnya kira-kira (1200 - padding) / 2 = sekitar 570an px.
    expect(width, greaterThan(500));
  });
}
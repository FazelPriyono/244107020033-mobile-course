import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

import 'pages/todo_page.dart';
import 'pages/product_page.dart'; // Import ProductPage
import 'pages/stats_page.dart'; // Import StatsPage

void main() => runApp(const ProviderScope(child: MyApp()));

// 1. Konfigurasi GoRouter
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TodoPage(), // Halaman utama ToDo
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductPage(), // Halaman Praktikum 3
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsPage(), // Halaman statistik
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Gunakan MaterialApp.router
    return MaterialApp.router(
      title: 'Week 3 - Navigation & State',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: _router, // 3. Masukkan konfigurasi router di sini
    );
  }
}

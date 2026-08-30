import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 72),
              SizedBox(height: 16),
              Text('Fazel Priyono', style: TextStyle(fontSize: 24)),
              Text('244107020033', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
              Text('Teknik Informatika - 3D', style: TextStyle(fontSize: 20)),
              Text('Pemrograman Mobile - Minggu 1'),
            ],
          ),
        ),
      ),
    );
  }
}

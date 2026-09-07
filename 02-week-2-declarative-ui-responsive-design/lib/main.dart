import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// 1. Refactoring: Konstanta breakpoint didefinisikan satu kali di atas
const double kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    // Menyimpan daftar kartu agar tidak perlu ditulis berulang kali di dalam kondisi LayoutBuilder
    const List<Widget> myCards = [
      InfoCard(title: 'Assignments', value: '8'),
      InfoCard(title: 'Attendance', value: '92%'),
      InfoCard(title: 'Portfolio', value: 'Ready'),
      InfoCard(title: 'Current week', value: '02'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 4),
              // Aksesibilitas: Label untuk tombol penting
              Semantics(
                label: 'Tombol pengubah tema ${isDark ? 'gelap' : 'terang'}',
                child: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profil menggunakan Container, Row, Column, dan Expanded
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fazel Priyono',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIM: 244107020033 | Kelas: TI-3D',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Layout Responsif untuk Kartu (Menggunakan Flex/Column agar tidak overflow)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Versi 2 Kolom (Layar Lebar)
                if (constraints.maxWidth >= kWideBreakpoint) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: myCards[0]),
                            const SizedBox(width: 16),
                            Expanded(child: myCards[1]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: myCards[2]),
                            const SizedBox(width: 16),
                            Expanded(child: myCards[3]),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                // Versi 1 Kolom (Layar Sempit)
                else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        myCards[0],
                        const SizedBox(height: 16),
                        myCards[1],
                        const SizedBox(height: 16),
                        myCards[2],
                        const SizedBox(height: 16),
                        myCards[3],
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Refactoring: Ekstrak kartu informasi menjadi widget reusable
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    // 3. Refactoring: Menggunakan Theme.of(context) agar otomatis mengikuti mode terang/gelap
    final theme = Theme.of(context);

    return Semantics(
      label: 'Kartu informasi $title',
      value: value,
      excludeSemantics: true, // Menghindari screen reader membaca teks di dalam secara terpisah
      child: Card(
        elevation: 1,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme
                      .colorScheme
                      .primary, // Warna teks otomatis dari tema
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

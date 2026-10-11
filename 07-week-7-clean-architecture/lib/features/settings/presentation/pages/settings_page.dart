import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final settingsAsync = ref.watch(settingsInfoProvider);
    final isDark = darkModeAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Preferensi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card Pengaturan Tema
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: const Text('Tema Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  isDark ? 'Mode gelap aktif (Tema Deep Slate)' : 'Mode terang aktif (Tema Emerald Teal)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withAlpha(isDark ? 50 : 25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                value: isDark,
                onChanged: (val) {
                  ref.read(darkModeProvider.notifier).toggle();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card Riwayat Buka Aplikasi
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.blue),
              ),
              title: const Text('Terakhir Aplikasi Dibuka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: settingsAsync.when(
                data: (settings) => Text(
                  settings.lastOpenedAt != null
                      ? formatDisplayDate(settings.lastOpenedAt!)
                      : 'Baru pertama kali dibuka pada sesi ini',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                loading: () => const Text('Memuat riwayat...'),
                error: (_, _) => const Text('Tidak tersedia'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card Informasi Clean Architecture
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fitur Pengaturan (Clean Feature)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Feature-First: features/settings/',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildArchItem('Domain Layer', 'Entity AppSettings & UseCase ToggleThemeMode, GetSettings (Pure Dart).'),
                  _buildArchItem('Data Layer', 'SettingsRepositoryImpl membungkus akses preferensi lokal.'),
                  _buildArchItem('Presentation Layer', 'DarkModeNotifier disuntikkan via Riverpod Provider.'),
                  _buildArchItem('Status Sterilitas', 'UI steril dari akses penyimpanan lokal langsung (100% Lolos).'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

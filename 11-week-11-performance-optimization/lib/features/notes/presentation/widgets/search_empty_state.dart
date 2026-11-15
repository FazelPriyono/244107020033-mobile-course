import 'package:flutter/material.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.query,
    this.onAddNote,
    this.onClearQuery,
  });

  final String query;
  final VoidCallback? onAddNote;
  final VoidCallback? onClearQuery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withAlpha(isDark ? 40 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.note_alt_outlined,
                size: 48,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Tidak ada catatan yang cocok dengan pencarian.'
                  : 'Belum ada catatan bisnis.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Coba kata kunci pencarian yang lain atau periksa ejaan.'
                  : 'Tekan tombol "Tambah Catatan" untuk membuat entity baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (!isSearching && onAddNote != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAddNote,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Buat Catatan Pertama'),
              ),
            ] else if (isSearching && onClearQuery != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClearQuery,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Reset Pencarian'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/features/notes/domain/entities/note.dart';
import 'package:week11_performance_optimization/features/notes/presentation/providers/notes_providers.dart';
import 'package:week11_performance_optimization/features/notes/presentation/widgets/search_empty_state.dart';

void main() {
  group('SearchEmptyState Widget Tests', () {
    testWidgets('menampilkan pesan belum ada catatan saat query kosong', (
      tester,
    ) async {
      var addNoteClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(
              query: '',
              onAddNote: () {
                addNoteClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Belum ada catatan bisnis.'), findsOneWidget);
      expect(
        find.text('Tekan tombol "Tambah Catatan" untuk membuat entity baru.'),
        findsOneWidget,
      );
      expect(find.text('Buat Catatan Pertama'), findsOneWidget);

      await tester.tap(find.text('Buat Catatan Pertama'));
      await tester.pump();
      expect(addNoteClicked, isTrue);
    });

    testWidgets(
      'menampilkan pesan tidak ada catatan cocok saat query tidak kosong',
      (tester) async {
        var clearQueryClicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SearchEmptyState(
                query: 'flutter-arsitektur-xyz',
                onClearQuery: () {
                  clearQueryClicked = true;
                },
              ),
            ),
          ),
        );

        expect(
          find.text('Tidak ada catatan yang cocok dengan pencarian.'),
          findsOneWidget,
        );
        expect(
          find.text('Coba kata kunci pencarian yang lain atau periksa ejaan.'),
          findsOneWidget,
        );
        expect(find.text('Reset Pencarian'), findsOneWidget);

        await tester.tap(find.text('Reset Pencarian'));
        await tester.pump();
        expect(clearQueryClicked, isTrue);
      },
    );
  });

  group('Search & FilteredNotes Provider Integration Tests', () {
    testWidgets(
      'filteredNotesProvider memfilter catatan reaktif berdasarkan query',
      (tester) async {
        final now = DateTime(2026, 11, 15);
        final dummyNotes = [
          Note(
            id: 1,
            title: 'Beli susu',
            body: 'Di minimarket',
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Belajar Clean Arch',
            body: 'Use Case & Domain',
            updatedAt: now,
          ),
        ];

        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notesProvider.overrideWith((ref) => Future.value(dummyNotes)),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  final filtered = ref.watch(filteredNotesProvider);
                  return filtered.when(
                    data: (notes) => ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, i) => Text(notes[i].title),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Beli susu'), findsOneWidget);
        expect(find.text('Belajar Clean Arch'), findsOneWidget);

        // Ubah query pencarian
        capturedRef.read(searchQueryProvider.notifier).updateQuery('clean');
        await tester.pumpAndSettle();

        expect(find.text('Beli susu'), findsNothing);
        expect(find.text('Belajar Clean Arch'), findsOneWidget);

        // Ubah ke query yang tidak cocok
        capturedRef.read(searchQueryProvider.notifier).updateQuery('tak-ada');
        await tester.pumpAndSettle();

        expect(find.text('Beli susu'), findsNothing);
        expect(find.text('Belajar Clean Arch'), findsNothing);
      },
    );
  });
}

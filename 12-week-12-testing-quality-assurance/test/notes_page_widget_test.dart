import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week12_testing_quality_assurance/features/notes/presentation/pages/notes_page.dart';
import 'package:week12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  Future<void> pumpNotesPage(
    WidgetTester tester,
    FakeNoteRepository fake,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Catatan Baru'), findsOneWidget);
  }

  group('NotesPage — tampilan awal', () {
    testWidgets('menampilkan empty state saat belum ada catatan', (
      tester,
    ) async {
      await pumpNotesPage(tester, FakeNoteRepository());

      expect(find.text('Belum ada catatan bisnis.'), findsOneWidget);
      expect(find.byKey(const Key('add-note-fab')), findsOneWidget);
      expect(find.textContaining('Catatan (0)'), findsOneWidget);
    });

    testWidgets('menampilkan daftar catatan dari repository', (tester) async {
      final fake = FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Catatan Pertama',
            body: 'Isi pertama',
            updatedAt: DateTime(2026, 11, 15, 8),
          ),
          Note(
            id: 2,
            title: 'Catatan Kedua',
            body: 'Isi kedua',
            updatedAt: DateTime(2026, 11, 15, 9),
          ),
        ],
      );

      await pumpNotesPage(tester, fake);

      expect(find.text('Catatan Pertama'), findsOneWidget);
      expect(find.text('Catatan Kedua'), findsOneWidget);
      expect(find.textContaining('Catatan (2)'), findsOneWidget);
    });

    testWidgets('menampilkan pesan error saat repository gagal', (
      tester,
    ) async {
      final fake = FakeNoteRepository(
        fetchFailure: const LocalFailure('database terkunci'),
      );

      await pumpNotesPage(tester, fake);

      expect(find.textContaining('Gagal memuat catatan'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('NotesPage — tambah catatan', () {
    testWidgets('menolak judul kosong dan dialog tetap terbuka', (
      tester,
    ) async {
      final fake = FakeNoteRepository();
      await pumpNotesPage(tester, fake);
      await openAddDialog(tester);

      await tester.enterText(find.byKey(const Key('note-title-field')), '   ');
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul catatan tidak boleh kosong'), findsOneWidget);
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);
      expect(fake.addCalls, 0);
      expect(fake.notes, isEmpty);
    });

    testWidgets('menyimpan catatan valid dan menampilkannya di daftar', (
      tester,
    ) async {
      final fake = FakeNoteRepository();
      await pumpNotesPage(tester, fake);
      await openAddDialog(tester);

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        '  Catatan Uji Widget  ',
      );
      await tester.enterText(
        find.byKey(const Key('note-body-field')),
        'Dibuat dari widget test',
      );
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Uji Widget'), findsOneWidget);
      expect(
        find.text('Catatan tervalidasi & tersimpan via Clean Architecture.'),
        findsOneWidget,
      );
      expect(fake.notes, hasLength(1));
      expect(fake.notes.single.title, 'Catatan Uji Widget');
      expect(fake.notes.single.body, 'Dibuat dari widget test');
      expect(find.byKey(const Key('note-title-field')), findsNothing);
    });

    testWidgets('menampilkan error repository dan tidak menutup dialog', (
      tester,
    ) async {
      final fake = FakeNoteRepository(
        addFailure: const NetworkFailure('penyimpanan penuh'),
      );
      await pumpNotesPage(tester, fake);
      await openAddDialog(tester);

      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Catatan Gagal',
      );
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('penyimpanan penuh'), findsOneWidget);
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);
      expect(fake.notes, isEmpty);
    });

    testWidgets('pencarian memfilter daftar catatan', (tester) async {
      final fake = FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Belajar Flutter',
            body: 'Widget test',
            updatedAt: DateTime(2026, 11, 15, 8),
          ),
          Note(
            id: 2,
            title: 'Belanja Bulanan',
            body: 'Susu dan telur',
            updatedAt: DateTime(2026, 11, 15, 9),
          ),
        ],
      );
      await pumpNotesPage(tester, fake);

      await tester.enterText(
        find.byKey(const Key('search-note-field')),
        'flutter',
      );
      await tester.pumpAndSettle();

      expect(find.text('Belajar Flutter'), findsOneWidget);
      expect(find.text('Belanja Bulanan'), findsNothing);
    });
  });
}

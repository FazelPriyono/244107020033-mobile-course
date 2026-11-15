import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/notes/domain/entities/note.dart';
import 'package:week12_testing_quality_assurance/features/notes/presentation/pages/note_detail_page.dart';
import 'package:week12_testing_quality_assurance/features/notes/presentation/providers/notes_providers.dart';

import 'helpers/fake_note_repository.dart';

void main() {
  Future<GoRouter> pumpDetailPage(
    WidgetTester tester,
    FakeNoteRepository fake,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('HALAMAN DAFTAR')),
        ),
        GoRoute(
          path: '/note/:id',
          builder: (context, state) =>
              NoteDetailPage(id: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.push('/note/1');
    await tester.pumpAndSettle();
    return router;
  }

  FakeNoteRepository buildFake({Failure? updateFailure}) {
    return FakeNoteRepository(
      notes: [
        Note(
          id: 1,
          title: 'Catatan Awal',
          body: 'Isi awal',
          updatedAt: DateTime(2026, 11, 15, 9),
        ),
      ],
      updateFailure: updateFailure,
    );
  }

  group('NoteDetailPage — tampilan dan validasi', () {
    testWidgets('menampilkan data catatan pada form', (tester) async {
      await pumpDetailPage(tester, buildFake());

      expect(find.text('Detail & Edit Catatan'), findsOneWidget);
      expect(find.text('Entity #1'), findsOneWidget);
      expect(find.text('Catatan Awal'), findsOneWidget);
      expect(find.text('Isi awal'), findsOneWidget);
    });

    testWidgets('menolak judul kosong tanpa memanggil repository', (
      tester,
    ) async {
      final fake = buildFake();
      await pumpDetailPage(tester, fake);

      await tester.enterText(
        find.byKey(const Key('detail-title-field')),
        '   ',
      );
      await tester.tap(find.byKey(const Key('save-note-changes-button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul catatan tidak boleh kosong'), findsOneWidget);
      expect(fake.updateCalls, 0);
      expect(find.text('Detail & Edit Catatan'), findsOneWidget);
    });

    testWidgets('menyimpan perubahan valid lalu kembali ke daftar', (
      tester,
    ) async {
      final fake = buildFake();
      await pumpDetailPage(tester, fake);

      await tester.enterText(
        find.byKey(const Key('detail-title-field')),
        '  Catatan Revisi  ',
      );
      await tester.tap(find.byKey(const Key('save-note-changes-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Catatan berhasil diperbarui via UpdateNote UseCase!'),
        findsOneWidget,
      );
      expect(fake.notes.single.title, 'Catatan Revisi');
      expect(find.text('HALAMAN DAFTAR'), findsOneWidget);
    });

    testWidgets('menampilkan error saat update gagal', (tester) async {
      final fake = buildFake(
        updateFailure: const LocalFailure('baris terkunci'),
      );
      await pumpDetailPage(tester, fake);

      await tester.tap(find.byKey(const Key('save-note-changes-button')));
      await tester.pumpAndSettle();

      expect(find.text('baris terkunci'), findsOneWidget);
      expect(find.text('Detail & Edit Catatan'), findsOneWidget);
      expect(fake.notes.single.title, 'Catatan Awal');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week12_testing_quality_assurance/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur utama: tambah catatan, buka detail, lalu hapus', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-note-fab')), findsOneWidget);

    final title = 'Catatan Integrasi ${DateTime.now().millisecondsSinceEpoch}';

    // Tambah catatan melalui dialog yang memakai AddNote UseCase.
    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-title-field')), title);
    await tester.enterText(
      find.byKey(const Key('note-body-field')),
      'Dibuat oleh integration test Week 12',
    );
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);

    // Buka halaman detail dan pastikan data yang sama tampil.
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    expect(find.text('Detail & Edit Catatan'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(find.text('Dibuat oleh integration test Week 12'), findsOneWidget);

    // Bersihkan data agar database perangkat tidak menumpuk.
    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Detail & Edit Catatan'), findsNothing);
    expect(find.text(title), findsNothing);
  });
}

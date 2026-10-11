import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/pages/announcement_page.dart';

void main() {
  testWidgets('AnnouncementPage menampilkan id pengumuman', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnnouncementPage(id: '3'),
      ),
    );
    expect(find.text('Pengumuman #3'), findsOneWidget);
    expect(find.text('ID Pengumuman: 3'), findsOneWidget);
  });
}

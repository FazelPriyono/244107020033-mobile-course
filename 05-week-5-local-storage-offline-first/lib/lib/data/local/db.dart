import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> _createTables(Database db, int version) async {
  await db.execute('''
    CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE cached_posts(
      id INTEGER PRIMARY KEY,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL
    )
  ''');
}

Future<Database> openNotesDb() async {
  if (kIsWeb) {
    // Jalankan databaseFactory khusus web jika di-build untuk Chrome/Edge
    var factory = databaseFactoryFfiWeb;
    return factory.openDatabase(
      'offline_notes.db',
      options: OpenDatabaseOptions(version: 1, onCreate: _createTables),
    );
  }
  // Fallback untuk Mobile (Android/iOS)
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: _createTables,
  );
}

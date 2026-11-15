import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Versi 2 menambahkan index untuk query yang paling sering dipakai.
const int kNotesDbVersion = 2;

Future<void> _createIndexes(Database db) async {
  // `fetchNotes` selalu `ORDER BY updated_at DESC`; index ini menghindari
  // full table scan + sort ketika jumlah catatan bertambah.
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at DESC)',
  );
  // Badge dirty dan `markAllSynced` memfilter kolom dirty.
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_notes_dirty ON notes(dirty)',
  );
}

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
  await _createIndexes(db);
}

Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await _createIndexes(db);
  }
}

Future<Database> openNotesDb() async {
  if (kIsWeb) {
    var factory = databaseFactoryFfiWeb;
    return factory.openDatabase(
      'offline_notes.db',
      options: OpenDatabaseOptions(
        version: kNotesDbVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      ),
    );
  }
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: kNotesDbVersion,
    onCreate: _createTables,
    onUpgrade: _upgradeTables,
  );
}

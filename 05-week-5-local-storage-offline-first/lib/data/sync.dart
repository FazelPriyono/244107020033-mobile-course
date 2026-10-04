import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'repositories/note_repository.dart';

class Post {
  final int id;
  final String title;
  final String body;
  
  Post({required this.id, required this.title, required this.body});
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();
  final rows = await db.query('cached_posts');
  if (rows.isNotEmpty) {
    final payload = rows.first['payload'] as String;
    final List<dynamic> jsonList = jsonDecode(payload);
    return jsonList.map((json) => Post.fromJson(json)).toList();
  }
  return [];
}

Future<void> refreshPostsInBackground() async {
  try {
    final dio = Dio();
    final response = await dio.get('https://jsonplaceholder.typicode.com/posts');
    if (response.statusCode == 200) {
      final db = await openNotesDb();
      final payload = jsonEncode(response.data);
      await db.insert('cached_posts', {
        'id': 1,
        'payload': payload,
        'cached_at': DateTime.now().toIso8601String()
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  } catch (e) {
    // Ignore error in background
  }
}

Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts(); // dari tabel cached_posts
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
  refreshPostsInBackground();
  return cached;
}

Future<int> _syncNotesImpl(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

// Keep backward-compatible top-level name.
Future<int> syncNotes(NoteRepository repo) => _syncNotesImpl(repo);

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// Wraps [syncNotes] so the UI can obtain it via ref.read(syncServiceProvider).
class SyncService {
  Future<int> syncNotes(NoteRepository repo) => _syncNotesImpl(repo);
}

// ignore: non_constant_identifier_names
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// ---------------------------------------------------------------------------
// Force-offline toggle
// ---------------------------------------------------------------------------

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

// ---------------------------------------------------------------------------
// Cache-first posts provider
// ---------------------------------------------------------------------------

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => loadPostsCacheFirst();

  Future<void> manualRefresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await refreshPostsInBackground();
      return readCachedPosts();
    });
  }
}

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
      CachedPostsNotifier.new,
    );

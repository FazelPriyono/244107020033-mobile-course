import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNoteById(id);
});

class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _populateData(Note note) {
    if (!_initialized) {
      _titleController.text = note.title;
      _bodyController.text = note.body;
      _initialized = true;
    }
  }

  Future<void> _saveNote(Note originalNote) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = originalNote.copyWith(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        updatedAt: DateTime.now(),
        dirty: true,
      );

      final repo = ref.read(noteRepositoryProvider);
      await repo.updateNote(updated);

      ref.invalidate(noteDetailProvider(widget.id));
      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Catatan diperbarui (Tersimpan lokal, ditandai belum disinkron).',
            ),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text(
          'Catatan ini akan dihapus dari penyimpanan lokal SQLite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(widget.id);
      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Catatan',
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Terjadi kesalahan: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(noteDetailProvider(widget.id)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (note) {
          if (note == null) {
            return const Center(
              child: Text('Catatan tidak ditemukan di penyimpanan lokal.'),
            );
          }

          _populateData(note);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: note.dirty
                        ? Colors.amber.shade100
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: note.dirty
                          ? Colors.amber.shade700
                          : Colors.green.shade600,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        note.dirty
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined,
                        color: note.dirty
                            ? Colors.amber.shade900
                            : Colors.green.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.dirty
                              ? 'Status: Belum Tersinkron (Dirty = 1)'
                              : 'Status: Tersinkron (Dirty = 0)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: note.dirty
                                ? Colors.amber.shade900
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                      Text(
                        'ID: ${note.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: note.dirty
                              ? Colors.amber.shade900
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Catatan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Isi Catatan',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terakhir diperbarui: ${note.updatedAt}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _saveNote(note),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';

/// Item daftar catatan.
///
/// Optimasi Week 11:
/// - subtree dibungkus [RepaintBoundary] agar paint satu item terisolasi
///   (catatan: `ListView.builder` sudah menambahkan boundary otomatis; boundary
///   ini menjaga isolasi yang sama saat tile dipakai di scrollable kustom);
/// - konten dipecah menjadi widget `const`/stateless yang lebih kecil sehingga
///   perubahan pada satu bagian tidak membangun ulang seluruh tile;
/// - style statis memakai `const` agar tidak dialokasikan ulang tiap build.
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NoteAvatar(isDark: isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NoteHeader(note: note),
                        const SizedBox(height: 6),
                        _NoteSnippet(body: note.body, isDark: isDark),
                        const SizedBox(height: 10),
                        _NoteFooter(note: note),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DeleteNoteButton(onDelete: onDelete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteAvatar extends StatelessWidget {
  const _NoteAvatar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withAlpha(isDark ? 50 : 25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.sticky_note_2_outlined,
        color: Color(0xFF0F766E),
        size: 24,
      ),
    );
  }
}

class _NoteHeader extends StatelessWidget {
  const _NoteHeader({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            note.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _NoteStatusBadge(dirty: note.dirty),
      ],
    );
  }
}

class _NoteStatusBadge extends StatelessWidget {
  const _NoteStatusBadge({required this.dirty});

  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final Color background = dirty
        ? Colors.amber.shade100
        : Colors.teal.shade50;
    final Color foreground = dirty
        ? Colors.amber.shade900
        : Colors.teal.shade800;
    final Color border = dirty ? Colors.amber.shade400 : Colors.teal.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dirty ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            size: 11,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            dirty ? 'Lokal (Dirty)' : 'SQLite',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSnippet extends StatelessWidget {
  const _NoteSnippet({required this.body, required this.isDark});

  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatNoteSnippet(body: body),
      style: TextStyle(
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        fontSize: 13,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NoteFooter extends StatelessWidget {
  const _NoteFooter({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          formatDisplayDate(note.updatedAt),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          'Entity #${note.id ?? 'new'}',
          style: TextStyle(
            color: const Color(0xFF0F766E).withAlpha(180),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DeleteNoteButton extends StatelessWidget {
  const _DeleteNoteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: Colors.red.shade400,
        size: 20,
      ),
      tooltip: 'Hapus Catatan',
      onPressed: onDelete,
      visualDensity: VisualDensity.compact,
    );
  }
}

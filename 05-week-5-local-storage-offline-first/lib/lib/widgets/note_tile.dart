import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const NoteTile({
    super.key,
    required this.note,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty)
            const Badge(
              label: Text('belum tersinkron'),
              backgroundColor: Colors.orange,
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap ?? () {
        context.push('/note/${note.id}');
      },
    );
  }
}

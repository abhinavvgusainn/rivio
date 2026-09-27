import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class NoteSubjectCard extends StatelessWidget {
  const NoteSubjectCard({
    super.key,
    required this.subject,
    required this.fileCount,
    required this.onTap,
    required this.onDelete,
  });
  final NoteSubject subject;
  final int fileCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = RivioColors.subject(subject.colorHex);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.folder_open_rounded, color: accent, size: 27),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Text(
          '$fileCount ${fileCount == 1 ? 'PDF file' : 'PDF files'}',
          style: TextStyle(color: accent, fontSize: 13),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete subject?'),
                  content: Text(
                    '“${subject.name}” and its saved PDF links will be removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete subject')),
          ],
        ),
      ),
    );
  }
}

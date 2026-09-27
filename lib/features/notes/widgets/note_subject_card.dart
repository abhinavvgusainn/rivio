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
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: RivioColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.folder_outlined, color: RivioColors.primary),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          fileCount == 1 ? '1 PDF' : '$fileCount PDFs',
          style: const TextStyle(color: RivioColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: RivioColors.textSecondary),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class PdfTile extends StatelessWidget {
  const PdfTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  final NoteFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.picture_as_pdf, color: RivioColors.primary),
        title: Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: RivioColors.textSecondary),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

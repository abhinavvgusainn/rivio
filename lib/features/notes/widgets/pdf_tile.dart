import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE2DF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Center(
          child: Text(
            'PDF',
            style: TextStyle(
              color: Color(0xFFB8322D),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      title: Text(
        file.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Added ${DateFormat('MMM d').format(file.addedAt)}',
        style: const TextStyle(color: RivioColors.secondaryText),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove PDF?'),
                content: Text(
                  'Remove “${file.fileName}” from this subject? The original file stays on your device.',
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
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'delete', child: Text('Remove PDF')),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class FlashcardSubjectCard extends StatelessWidget {
  const FlashcardSubjectCard({
    super.key,
    required this.subject,
    required this.deckCount,
    required this.onTap,
    required this.onDelete,
  });

  final FlashcardSubject subject;
  final int deckCount;
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
          child: const Icon(Icons.style_outlined, color: RivioColors.primary),
        ),
        title: Text(subject.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          deckCount == 1 ? '1 deck' : '$deckCount decks',
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

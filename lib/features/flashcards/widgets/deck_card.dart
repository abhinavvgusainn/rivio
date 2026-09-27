import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.deck,
    required this.cardCount,
    required this.onTap,
    required this.onDelete,
  });

  final FlashcardDeck deck;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.style, color: RivioColors.primary),
        title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          cardCount == 1 ? '1 card' : '$cardCount cards',
          style: const TextStyle(color: RivioColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: RivioColors.textSecondary),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

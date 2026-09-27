import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class FlashcardSubjectCard extends StatelessWidget {
  const FlashcardSubjectCard({
    super.key,
    required this.subject,
    required this.deckCount,
    required this.cardCount,
    required this.onTap,
    required this.onCreateDeck,
  });
  final FlashcardSubject subject;
  final int deckCount;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                subject.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
          ),
          Text(
            '$deckCount decks · $cardCount cards',
            style: const TextStyle(
              color: RivioColors.secondaryText,
              fontSize: 12,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Subject performance',
            onPressed: onTap,
            icon: const Icon(
              Icons.query_stats_outlined,
              color: RivioColors.green,
            ),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: onCreateDeck,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Create Deck'),
        style: OutlinedButton.styleFrom(
          foregroundColor: RivioColors.green,
          side: BorderSide(color: RivioColors.green.withValues(alpha: .3)),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    ],
  );
}

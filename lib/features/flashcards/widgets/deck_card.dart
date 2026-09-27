import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.deck,
    required this.cards,
    required this.onStudy,
    required this.onOpen,
    required this.onDelete,
  });
  final FlashcardDeck deck;
  final List<Flashcard> cards;
  final VoidCallback onStudy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mastered = cards.where((card) => card.consecutiveCorrect >= 3).length;
    final progress = cards.isEmpty ? 0.0 : mastered / cards.length;
    final dueToday = cards
        .where(
          (card) =>
              card.nextReviewAt == null ||
              !card.nextReviewAt!.isAfter(DateTime.now()),
        )
        .length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              color: dueToday > 0 ? RivioColors.green : RivioColors.border,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onOpen,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                deck.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (cards.isNotEmpty) _MasteryBadge(progress: progress),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${cards.length} cards · ${cards.isEmpty
                          ? 'New deck'
                          : dueToday > 0
                          ? 'Next review: Today'
                          : 'Spaced repetition'}',
                      style: const TextStyle(
                        color: RivioColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    if (cards.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE9EDE9),
                          color: RivioColors.green,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onOpen,
                          tooltip: 'Edit deck',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: cards.isEmpty ? null : onStudy,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RivioColors.green,
                            side: const BorderSide(color: RivioColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: const Text(
                            'Study',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete deck?'),
                                  content: Text(
                                    '“${deck.name}” and its ${cards.length} cards will be permanently removed.',
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
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete deck'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: progress >= .8 ? RivioColors.mint : const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '$percent% mastered',
        style: TextStyle(
          fontSize: 11,
          color: progress >= .8 ? RivioColors.green : RivioColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../database/database.dart';
import 'review_screen.dart';
import 'widgets/add_card_form.dart';

/// Cards inside one deck: add/edit/delete, plus entry into review mode.
class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key, required this.database, required this.deck});

  final AppDatabase database;
  final FlashcardDeck deck;

  Future<void> _addCard(BuildContext context) async {
    final result = await showAddCardSheet(context);
    if (result == null) return;
    await database.addCard(
      deckId: deck.id,
      front: result.front,
      back: result.back,
    );
  }

  Future<void> _editCard(BuildContext context, Flashcard card) async {
    final result = await showAddCardSheet(context);
    if (result == null) return;
    await database.updateCard(card.copyWith(
      front: result.front,
      back: result.back,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Flashcard>>(
        stream: database.watchCards(deck.id),
        builder: (context, snapshot) {
          final cards = snapshot.data ?? const [];

          if (cards.isEmpty) {
            return const Center(child: Text('Add a card to this deck'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start review'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ReviewScreen(database: database, cards: cards),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _editCard(context, card),
                        title: Text(
                          card.front,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          card.back,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: RivioColors.textSecondary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: RivioColors.textSecondary),
                          onPressed: () => database.deleteCard(card.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

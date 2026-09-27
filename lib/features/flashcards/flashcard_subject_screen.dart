import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../notes/widgets/add_subject_dialog.dart';
import 'deck_screen.dart';
import 'widgets/deck_card.dart';

/// Decks inside one flashcard subject.
class FlashcardSubjectScreen extends StatelessWidget {
  const FlashcardSubjectScreen({
    super.key,
    required this.database,
    required this.subject,
  });

  final AppDatabase database;
  final FlashcardSubject subject;

  Future<void> _createDeck(BuildContext context) async {
    final name = await showAddSubjectDialog(context, title: 'New deck');
    if (name == null || name.isEmpty) return;
    await database.createDeck(subjectId: subject.id, name: name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDeck(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FlashcardDeck>>(
        stream: database.watchDecks(subject.id),
        builder: (context, snapshot) {
          final decks = snapshot.data ?? const [];

          if (decks.isEmpty) {
            return const Center(child: Text('Add a deck to this subject'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return StreamBuilder<List<Flashcard>>(
                stream: database.watchCards(deck.id),
                builder: (context, cardSnapshot) {
                  final cardCount = cardSnapshot.data?.length ?? 0;
                  return DeckCard(
                    deck: deck,
                    cardCount: cardCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DeckScreen(database: database, deck: deck),
                      ),
                    ),
                    onDelete: () => database.deleteDeck(deck.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../notes/widgets/add_subject_dialog.dart';
import 'deck_screen.dart';
import 'review_screen.dart';
import 'widgets/deck_card.dart';

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
    if (name != null && context.mounted) {
      await database.createDeck(subjectId: subject.id, name: name);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createDeck(context),
      icon: const Icon(Icons.add),
      label: const Text('Create Deck'),
      backgroundColor: RivioColors.green,
      foregroundColor: Colors.white,
    ),
    body: StreamBuilder<List<FlashcardDeck>>(
      stream: database.watchDecks(subject.id),
      builder: (context, deckSnapshot) {
        final decks = deckSnapshot.data ?? const <FlashcardDeck>[];
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(subject.name),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  subject.name,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (decks.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.layers_outlined,
                    title: 'No decks yet',
                    body: 'Create a deck to start learning this subject.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.separated(
                  itemCount: decks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return StreamBuilder<List<Flashcard>>(
                      stream: database.watchCards(deck.id),
                      builder: (context, cardSnapshot) {
                        final cards = cardSnapshot.data ?? const <Flashcard>[];
                        final dueCards = cards
                            .where(
                              (card) =>
                                  card.nextReviewAt == null ||
                                  !card.nextReviewAt!.isAfter(DateTime.now()),
                            )
                            .toList();
                        return DeckCard(
                          deck: deck,
                          cards: cards,
                          onStudy: () {
                            if (cards.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(
                                    database: database,
                                    deck: deck,
                                    subjectName: subject.name,
                                    cards: dueCards.isEmpty ? cards : dueCards,
                                  ),
                                ),
                              );
                            }
                          },
                          onOpen: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeckScreen(
                                database: database,
                                deck: deck,
                                subjectName: subject.name,
                              ),
                            ),
                          ),
                          onDelete: () => database.deleteDeck(deck.id),
                        );
                      },
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        );
      },
    ),
  );
}

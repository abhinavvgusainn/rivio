import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/interaction_feedback.dart';
import 'review_screen.dart';
import 'widgets/add_card_form.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({
    super.key,
    required this.database,
    required this.deck,
    required this.subjectName,
  });
  final AppDatabase database;
  final FlashcardDeck deck;
  final String subjectName;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  AppDatabase get database => widget.database;
  FlashcardDeck get deck => widget.deck;
  String get subjectName => widget.subjectName;
  late String _deckName = deck.name;

  Future<void> _addCard(BuildContext context) async {
    final card = await showAddCardForm(context);
    if (card == null) return;
    await database.addCard(deckId: deck.id, front: card.front, back: card.back);
    InteractionFeedback.cardCreated();
  }

  Future<void> _editCard(BuildContext context, Flashcard card) async {
    final draft = await showAddCardForm(
      context,
      front: card.front,
      back: card.back,
    );
    if (draft != null) {
      await database.updateCard(
        card.copyWith(front: draft.front, back: draft.back),
      );
    }
  }

  Future<void> _renameDeck(BuildContext context) async {
    final name = await showNameDialog(
      context,
      title: 'Rename deck',
      initialValue: deck.name,
      hint: 'Deck name',
    );
    if (name != null && mounted) {
      await database.updateDeck(deck.copyWith(name: name));
      setState(() => _deckName = name);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _addCard(context),
      icon: const Icon(Icons.add),
      label: const Text('Add card'),
      backgroundColor: RivioColors.green,
      foregroundColor: Colors.white,
    ),
    body: StreamBuilder<List<Flashcard>>(
      stream: database.watchCards(deck.id),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? const <Flashcard>[];
        final due = cards
            .where(
              (card) =>
                  card.nextReviewAt == null ||
                  !card.nextReviewAt!.isAfter(DateTime.now()),
            )
            .toList();
        final known = cards
            .where((card) => card.consecutiveCorrect >= 3)
            .length;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                _deckName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: 'Rename deck',
                  onPressed: () => _renameDeck(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: const TextStyle(
                        color: RivioColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _deckName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${cards.length} cards · $known mastered · ${due.length} due for review',
                      style: const TextStyle(color: RivioColors.secondaryText),
                    ),
                    if (cards.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewScreen(
                                database: database,
                                deck: deck,
                                subjectName: subjectName,
                                cards: due.isEmpty ? cards : due,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            due.isEmpty
                                ? 'Review deck again'
                                : 'Study ${due.length} due cards',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (cards.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.style_outlined,
                    title: 'Build this deck',
                    body: 'Add your first question and answer with the button below.',
                    tint: Color(0xFFE9F5ED),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
                sliver: SliverList.separated(
                  itemCount: cards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _editCard(context, card),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE5F4EB),
                          child: Icon(
                            Icons.quiz_outlined,
                            color: RivioColors.green,
                          ),
                        ),
                        title: Text(
                          card.front,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${card.timesReviewed} reviews · ${card.consecutiveCorrect} correct in a row',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete card?'),
                                  content: Text(
                                    'Remove “${card.front}” from this deck?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        database.deleteCard(card.id);
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
                              child: Text('Delete card'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    ),
  );
}

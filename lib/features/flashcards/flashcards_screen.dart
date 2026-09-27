import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/interaction_feedback.dart';
import '../notes/widgets/add_subject_dialog.dart';
import 'deck_screen.dart';
import 'review_screen.dart';
import 'widgets/deck_card.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  int? _subjectFilter;
  _ReviewTarget? _activeReview;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final name = await showAddSubjectDialog(
      context,
      title: 'New flashcard subject',
    );
    if (name == null || !mounted) return;
    await widget.database.createFlashcardSubject(name);
    InteractionFeedback.tap();
  }

  Future<void> _createDeck(FlashcardSubject subject) async {
    final name = await showNameDialog(
      context,
      title: 'Create a deck',
      hint: 'For example, Chapter 1 — Cost Sheet',
    );
    if (name == null || !mounted) return;
    await widget.database.createDeck(subjectId: subject.id, name: name);
    InteractionFeedback.tap();
  }

  void _startStudy(
    FlashcardDeck deck,
    FlashcardSubject subject,
    List<Flashcard> cards,
  ) {
    if (cards.isEmpty) return;
    final now = DateTime.now();
    final due = cards
        .where(
          (card) =>
              card.nextReviewAt == null || !card.nextReviewAt!.isAfter(now),
        )
        .toList();
    setState(
      () => _activeReview = _ReviewTarget(
        deck: deck,
        subjectName: subject.name,
        cards: due.isEmpty ? cards : due,
      ),
    );
    InteractionFeedback.tap();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _showSubjectStats(FlashcardSubject subject) async {
    await showDialog<void>(
      context: context,
      builder: (context) => StreamBuilder<List<SubjectEffort>>(
        stream: widget.database.watchSubjectEfforts(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <SubjectEffort>[];
          SubjectEffort? effort;
          for (final item in items) {
            if (item.subjectId == subject.id) {
              effort = item;
              break;
            }
          }
          return AlertDialog(
            title: Text(subject.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subject effort matrix',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('Flashcards made  ·  ${effort?.cardsCreated ?? 0}'),
                Text('Flashcards reviewed  ·  ${effort?.cardsReviewed ?? 0}'),
                const Divider(height: 22),
                Text(
                  'Effort score  ·  ${effort?.effortScore ?? 0}',
                  style: const TextStyle(
                    color: RivioColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One point for each card made, plus two points for each completed card review.',
                  style: TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSubject(FlashcardSubject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          '“${subject.name}” and all its decks and cards will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.database.deleteFlashcardSubject(subject.id);
      if (_subjectFilter == subject.id) setState(() => _subjectFilter = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addSubject,
      backgroundColor: RivioColors.green,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Subject'),
    ),
    body: StreamBuilder<List<FlashcardSubject>>(
      stream: widget.database.watchFlashcardSubjects(),
      builder: (context, subjectSnapshot) {
        final subjects = subjectSnapshot.data ?? const <FlashcardSubject>[];
        final visibleSubjects = subjects
            .where(
              (subject) =>
                  _subjectFilter == null || subject.id == _subjectFilter,
            )
            .toList();
        final slivers = <Widget>[
          StudySliverAppBar(onSearch: _toggleSearch),
          if (_searching) _searchSliver(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 7),
            sliver: SliverToBoxAdapter(child: _titleRow(subjects.length)),
          ),
          SliverToBoxAdapter(child: _subjectChips(subjects)),
        ];

        if (visibleSubjects.isEmpty) {
          slivers.add(
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 12),
              sliver: SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.style_outlined,
                  title: 'Start a subject',
                  body: 'Create a subject, then build a deck of flashcards.',
                  tint: Color(0xFFE9F5ED),
                ),
              ),
            ),
          );
        } else {
          for (final subject in visibleSubjects) {
            slivers.add(_subjectSection(subject));
          }
        }

        final activeReview = _activeReview;
        if (activeReview != null) {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              sliver: SliverToBoxAdapter(
                child: FlashcardReviewPanel(
                  key: ValueKey(activeReview.deck.id),
                  database: widget.database,
                  deck: activeReview.deck,
                  subjectName: activeReview.subjectName,
                  cards: activeReview.cards,
                  onFinished: () {
                    if (mounted) setState(() => _activeReview = null);
                  },
                ),
              ),
            ),
          );
        }
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 92)));
        return CustomScrollView(slivers: slivers);
      },
    ),
  );

  Widget _searchSliver() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: 'Search subjects, decks, cards…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    ),
  );

  Widget _titleRow(int subjectCount) => Row(
    children: [
      const Expanded(
        child: Text(
          'Flashcards',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$subjectCount Subjects Available',
          style: const TextStyle(
            fontSize: 11,
            color: RivioColors.secondaryText,
          ),
        ),
      ),
    ],
  );

  Widget _subjectChips(List<FlashcardSubject> subjects) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        _subjectChip(
          'All Subjects',
          _subjectFilter == null,
          () => setState(() => _subjectFilter = null),
        ),
        ...subjects.map(
          (subject) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: StreamBuilder<List<FlashcardDeck>>(
              stream: widget.database.watchDecks(subject.id),
              builder: (context, snapshot) => _subjectChip(
                '${subject.name} (${snapshot.data?.length ?? 0})',
                _subjectFilter == subject.id,
                () => setState(() => _subjectFilter = subject.id),
                color: RivioColors.subject(subject.colorHex),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _subjectChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color color = RivioColors.green,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    selectedColor: color,
    backgroundColor: color.withValues(alpha: .12),
    labelStyle: TextStyle(
      color: selected ? Colors.white : color,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
    side: BorderSide(color: selected ? color : color.withValues(alpha: .35)),
  );

  Widget _subjectSection(FlashcardSubject subject) => SliverToBoxAdapter(
    child: StreamBuilder<List<FlashcardDeck>>(
      stream: widget.database.watchDecks(subject.id),
      builder: (context, deckSnapshot) {
        final decks = deckSnapshot.data ?? const <FlashcardDeck>[];
        final query = _query.toLowerCase();
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${decks.length} decks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: RivioColors.secondaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showSubjectStats(subject),
                    child: const Text('View stats'),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _deleteSubject(subject);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete subject'),
                      ),
                    ],
                  ),
                ],
              ),
              if (decks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: EmptyState(
                    icon: Icons.layers_outlined,
                    title: 'No decks yet',
                    body: 'Create a deck for this subject.',
                    tint: const Color(0xFFF1F4F1),
                  ),
                ),
              for (final deck in decks) _deckTile(deck, subject, query),
              OutlinedButton.icon(
                onPressed: () => _createDeck(subject),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Deck'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RivioColors.green,
                  side: BorderSide(
                    color: RivioColors.green.withValues(alpha: .28),
                  ),
                  minimumSize: const Size.fromHeight(43),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _deckTile(
    FlashcardDeck deck,
    FlashcardSubject subject,
    String query,
  ) => StreamBuilder<List<Flashcard>>(
    stream: widget.database.watchCards(deck.id),
    builder: (context, cardSnapshot) {
      final cards = cardSnapshot.data ?? const <Flashcard>[];
      final matches =
          query.isEmpty ||
          subject.name.toLowerCase().contains(query) ||
          deck.name.toLowerCase().contains(query) ||
          cards.any(
            (card) =>
                card.front.toLowerCase().contains(query) ||
                card.back.toLowerCase().contains(query),
          );
      if (!matches) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DeckCard(
          deck: deck,
          cards: cards,
          onStudy: () => _startStudy(deck, subject, cards),
          onOpen: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeckScreen(
                database: widget.database,
                deck: deck,
                subjectName: subject.name,
              ),
            ),
          ),
          onDelete: () => widget.database.deleteDeck(deck.id),
        ),
      );
    },
  );
}

class _ReviewTarget {
  const _ReviewTarget({
    required this.deck,
    required this.subjectName,
    required this.cards,
  });
  final FlashcardDeck deck;
  final String subjectName;
  final List<Flashcard> cards;
}

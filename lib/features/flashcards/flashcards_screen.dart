import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../notes/widgets/add_subject_dialog.dart';
import 'flashcard_subject_screen.dart';
import 'widgets/flashcard_subject_card.dart';

/// Top-level Flashcards screen: a list of flashcard subjects.
/// Independent from Notes — no shared subjects or tables.
class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key, required this.database});

  final AppDatabase database;

  Future<void> _createSubject(BuildContext context) async {
    final name =
        await showAddSubjectDialog(context, title: 'New flashcard subject');
    if (name == null || name.isEmpty) return;
    await database.createFlashcardSubject(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createSubject(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FlashcardSubject>>(
        stream: database.watchFlashcardSubjects(),
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? const [];

          if (subjects.isEmpty) {
            return const Center(
              child: Text('Add a subject to start building decks'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return StreamBuilder<List<FlashcardDeck>>(
                stream: database.watchDecks(subject.id),
                builder: (context, deckSnapshot) {
                  final deckCount = deckSnapshot.data?.length ?? 0;
                  return FlashcardSubjectCard(
                    subject: subject,
                    deckCount: deckCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlashcardSubjectScreen(
                          database: database,
                          subject: subject,
                        ),
                      ),
                    ),
                    onDelete: () =>
                        database.deleteFlashcardSubject(subject.id),
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

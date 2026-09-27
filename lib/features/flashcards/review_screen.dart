import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../database/database.dart';
import 'widgets/flashcard_view.dart';

/// Steps through a deck's cards one at a time. Reaching the end of
/// the deck is the "meaningful action" that logs a StudySession —
/// just opening the review screen does not.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.database,
    required this.cards,
  });

  final AppDatabase database;
  final List<Flashcard> cards;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _index = 0;
  final _stopwatch = Stopwatch()..start();

  Future<void> _next() async {
    final current = widget.cards[_index];
    await widget.database.markCardReviewed(current.id);

    if (_index == widget.cards.length - 1) {
      await _finishReview();
      return;
    }
    setState(() => _index++);
  }

  Future<void> _finishReview() async {
    _stopwatch.stop();
    await widget.database.logStudySession(
      type: StudySessionType.flashcardReview,
      durationSeconds: _stopwatch.elapsed.inSeconds,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Card ${_index + 1} of ${widget.cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / widget.cards.length,
              color: RivioColors.primary,
              backgroundColor: RivioColors.border,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: FlashcardView(front: card.front, back: card.back),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the card to flip it',
              style: TextStyle(color: RivioColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _index == widget.cards.length - 1 ? 'Finish' : 'Next card',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

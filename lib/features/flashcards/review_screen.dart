import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../database/database.dart';
import '../../services/interaction_feedback.dart';
import 'widgets/flashcard_view.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.database,
    required this.deck,
    required this.subjectName,
    required this.cards,
  });
  final AppDatabase database;
  final FlashcardDeck deck;
  final String subjectName;
  final List<Flashcard> cards;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverToBoxAdapter(
            child: FlashcardReviewPanel(
              database: database,
              deck: deck,
              subjectName: subjectName,
              cards: cards,
              onFinished: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    ),
  );
}

class FlashcardReviewPanel extends StatefulWidget {
  const FlashcardReviewPanel({
    super.key,
    required this.database,
    required this.deck,
    required this.subjectName,
    required this.cards,
    required this.onFinished,
  });
  final AppDatabase database;
  final FlashcardDeck deck;
  final String subjectName;
  final List<Flashcard> cards;
  final VoidCallback onFinished;

  @override
  State<FlashcardReviewPanel> createState() => _FlashcardReviewPanelState();
}

class _FlashcardReviewPanelState extends State<FlashcardReviewPanel> {
  final _stopwatch = Stopwatch()..start();
  int _index = 0;
  int _knownCount = 0;
  int _againCount = 0;
  bool _revealed = false;
  bool _saving = false;
  bool _finished = false;

  Future<void> _rate(bool known) async {
    if (_saving || !_revealed || _finished) return;
    setState(() => _saving = true);
    final card = widget.cards[_index];
    await widget.database.markCardReviewed(card.id, known: known);
    if (!mounted) return;
    if (known) {
      _knownCount++;
    } else {
      _againCount++;
    }
    if (_index + 1 == widget.cards.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _saving = false;
    });
    InteractionFeedback.tap();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _stopwatch.stop();
    await widget.database.logStudySession(
      type: StudySessionType.flashcardReview,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      cardsReviewed: _index + 1,
      subjectId: widget.deck.subjectId,
    );
    if (!mounted) return;
    InteractionFeedback.celebrate();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeckCelebrationDialog(),
    );
    if (mounted) widget.onFinished();
  }

  Future<void> _closeEarly() async {
    if (_finished || _saving) return;
    if (_index == 0) {
      _stopwatch.stop();
      _finished = true;
      widget.onFinished();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this review?'),
        content: Text(
          '$_index cards have been rated. Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep studying'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End review'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _finished = true;
    _stopwatch.stop();
    await widget.database.logStudySession(
      type: StudySessionType.flashcardReview,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      cardsReviewed: _index,
      subjectId: widget.deck.subjectId,
    );
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    final progress = (_index + 1) / widget.cards.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.style_outlined,
                  color: RivioColors.green,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deck.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Active Review Session',
                        style: TextStyle(
                          color: RivioColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: RivioColors.mint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.cards.length}',
                    style: const TextStyle(
                      color: RivioColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _closeEarly,
                  icon: const Icon(Icons.close, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: RivioColors.green,
                backgroundColor: const Color(0xFFE9EDE9),
              ),
            ),
            const SizedBox(height: 14),
            FlashcardView(
              key: ValueKey(card.id),
              front: card.front,
              back: card.back,
              onFlipped: (isRevealed) {
                if (mounted && _revealed != isRevealed) {
                  setState(() => _revealed = isRevealed);
                }
              },
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving || !_revealed
                        ? null
                        : () => _rate(false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text("Didn't know"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB43B35),
                      backgroundColor: const Color(0xFFFFE0DE),
                      side: const BorderSide(color: Color(0xFFFFA39D)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving || !_revealed ? null : () => _rate(true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Knew it'),
                    style: FilledButton.styleFrom(
                      backgroundColor: RivioColors.green,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(Icons.done_all, color: RivioColors.green, size: 15),
                const SizedBox(width: 6),
                Text(
                  '$_index cards reviewed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: RivioColors.secondaryText,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_knownCount known',
                  style: const TextStyle(
                    fontSize: 11,
                    color: RivioColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_againCount need review',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC23F38),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeckCelebrationDialog extends StatefulWidget {
  const DeckCelebrationDialog({
    super.key,
    this.title = 'Deck complete!',
    this.subtitle = 'You showed up and put in the work. Nice one!',
  });
  final String title;
  final String subtitle;
  @override
  State<DeckCelebrationDialog> createState() => _DeckCelebrationDialogState();
}

class _DeckCelebrationDialogState extends State<DeckCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    content: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _ConfettiPainter(_controller.value),
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFFFE8B8),
                    child: Icon(
                      Icons.celebration_rounded,
                      color: Color(0xFFD98800),
                      size: 39,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: RivioColors.secondaryText),
          ),
        ],
      ),
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('That felt good'),
      ),
    ],
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;
  static const colors = [
    RivioColors.green,
    RivioColors.coral,
    RivioColors.blue,
    RivioColors.amber,
    RivioColors.lavender,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 42; index++) {
      final seed = index * 17.37;
      final x = (seed * 19 % size.width);
      final y = ((seed * 11 + progress * size.height * 1.7) % size.height);
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(
          alpha: (1 - progress * .55).clamp(0, 1),
        );
      if (index.isEven) {
        canvas.drawCircle(Offset(x, y), 2.4 + (index % 3), paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * math.pi + seed);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 6, height: 3),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

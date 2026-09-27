import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../services/interaction_feedback.dart';

class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.front,
    required this.back,
    this.onFlipped,
  });
  final String front;
  final String back;
  final ValueChanged<bool>? onFlipped;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  bool _showBack = false;

  void _toggle() {
    if (_showBack) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
    setState(() => _showBack = !_showBack);
    widget.onFlipped?.call(_showBack);
    InteractionFeedback.flip();
  }

  @override
  void didUpdateWidget(covariant FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.front != widget.front || oldWidget.back != widget.back) {
      _flip.value = 0;
      _showBack = false;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _toggle,
    child: AnimatedBuilder(
      animation: _flip,
      builder: (context, child) {
        final angle = _flip.value * 3.141592653589793;
        final backFace = angle > 1.5707963267948966;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .001)
            ..rotateY(angle),
          child: backFace
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.141592653589793),
                  child: child,
                )
              : child,
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 205),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _showBack ? const Color(0xFFF0F4F1) : const Color(0xFFF3F5F4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RivioColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _showBack ? 'ANSWER · DEFINITION' : 'PROMPT · QUESTION',
                  style: const TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showBack
                      ? Icons.check_circle_outline
                      : Icons.lightbulb_outline,
                  size: 19,
                  color: RivioColors.secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _showBack ? widget.back : widget.front,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: RivioColors.text,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: RivioColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: RivioColors.border),
                ),
                child: Text(
                  _showBack ? 'Tap to see question' : 'Tap to reveal answer  ↻',
                  style: const TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

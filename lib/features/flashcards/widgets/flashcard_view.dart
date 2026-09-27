import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A single flip-able flashcard used in the review screen.
/// Tapping flips between the front (question) and back (answer).
class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.front,
    required this.back,
  });

  final String front;
  final String back;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  bool _showingFront = true;

  void _flip() {
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showingFront = !_showingFront);
  }

  @override
  void didUpdateWidget(covariant FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.front != widget.front) {
      _controller.value = 0;
      _showingFront = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 3.14159;
          final isBack = angle > 3.14159 / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildFace(widget.back, isFront: false),
                  )
                : _buildFace(widget.front, isFront: true),
          );
        },
      ),
    );
  }

  Widget _buildFace(String text, {required bool isFront}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isFront ? RivioColors.surface : RivioColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RivioColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RivioColors.textPrimary,
        ),
      ),
    );
  }
}
